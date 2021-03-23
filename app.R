
### !!!! IMPORTANT !!!!! ###
## This code won't run properly for you until you authorise it to access your google account,
## and make a google sheets that it can write the submissions to.

### HOW TO DO THIS

# first, you will need to install and load the following packages (shiny already comes with R)

library(shiny)
library(shinyjs)
library(googlesheets4)
library(googledrive)

# These first few bits of code (making the google sheet, authorising the account), only need to be run once, 
# so they are commented out now. Just uncomment them and run them once the first time you set up your app, then 
# comment them out again once you deploy it.

## 1. SET UP AUTHORISATION TO EDIT FILES IN YOUR GOOGLE DRIVE

# Get the token and store it in a cache folder embedded in your app directory
# designate project-specific cache

options(gargle_oauth_cache = ".secrets")

# Authenticate in interactive mode (run the app) ONCE and check if the token 
# has been stored inside the .secrets folder, after that just comment out this line

# drive_auth() # Authenticate to produce the token in the cache folder

# Tell gargle to search the token in the secrets folder and to look
# for an auth given to a certain email (enter your email linked to googledrive!)

drive_auth(cache = ".secrets", email = "YOUREMAIL@gmail.com")
gs4_auth(token = drive_token())

## 2. Make google sheet

# You only need to make the google sheet once, so uncomment this line to do that, then comment it out again

# ss <- gs4_create("SurveyData")

# Get the sheet ID

# ss[1]

# Copy and paste the sheet_ID, storing it in a variable (replace the XXXXXXs here with your sheet ID)

sheet_ID <- "XXXXXXXXXXXXXXXXXXXXX"

# Read in the stimuli

stimuli <- read.csv('stimuli.csv',encoding="UTF-8")

# Make a vector to store the image links
images <- stimuli$Link

# Name the links so you know what image they refer to
names(images) <- stimuli$Image

# Make the first row in the google sheet these names (plus an extra column for the person's country). 
# You only need to uncomment this and do this once.

# sheet_append(data.frame(t((data.frame(c(names(images),'Country'))))),ss=sheet_ID)

### MAKING THE APP

# make a list of labels for food items
labels <- c("cake","tart","pie","biscuit","pastry","bun","bread")

# create a vector of the names of the images in a random order 
image_order <- sample(names(images))

# create the user interface
ui <- fluidPage(
    # use shinyjs in order to have hidden elements
    useShinyjs(),
    mainPanel(
        titlePanel("Baked goods survey"),
        # enclose stuff you want to treat as one element 
        # to hide and show at different points in the experiment in a div()
        div(id="instructions",
            includeHTML('instructions.html'),
            actionButton("Participate","Participate")),
        # the hidden function hides a div when the application starts up
        # add code in the server to show it when the user reaches a certain point
        # in the experiment
        hidden(div(id="experiment",
                   uiOutput("Stimulus"),
                   radioButtons("Choice","What is this?",labels,selected = character(0)),
                   textInput("Other","Other:"),
                   actionButton("Next","Next"))),
        hidden(div(id="finished",h3("Thanks for participating!"),
               h4("Before you submit, please let us know where you are from."),
               textInput("Country","Country of birth:"),
               actionButton("Submit","Submit")
               )),
        hidden(div(id="submitted",h3("Your answers have been submitted!")))
        
))


server <- function(input,output,session){
    
    useShinyjs()

    # This is what the server does when the user clicks participate
    observeEvent(input$Participate, {
        show("experiment")
        hide("instructions")
        # show the first image in image_order. Images contains the actual links to the images
        # and we use the name of the image (in image-order) as the key to access the image link
        # stored under that name in images
        output$Stimulus <- renderUI(tags$img(src=images[image_order[1]][[1]][1],height=150,width=150))
    })
    
    # make a variable to store the users choices of labels for the different images
    # we start with a vector of the right length full of numbers, and replace the numbers
    # with the users choices of labels as the experiment proceeds
    results <- c(1:length(images))
    
    # make a variable to count how many images you've shown, it starts at 1 because the first
    # image is already shown when the user clicks participate
    count <- 1
    
    # after this, a new image is shown every time the user clicks 'Next'
    onclick("Next",{
        # Reset the text in the 'Other' text input box to nothing every time they start a new image
        updateTextInput(session, "Other", value = "")
        
        # work out where in the results vector to store the person's response to the image.
        # match() returns the index of a given value (the image name at image_order[count]) in 
        # a given vector (in this case, names(images)). We want to store the results in the same
        # order that we have the names for the images in the header of the google sheet, so that
        # they are in the right columns when we write the results to the google sheet. 
        
        results_index<-match(image_order[count],names(images))
        
        # store the users input (their choice of label) in the right place in the results vector
        results[results_index]<-input$Choice
        
        # increase the image count by 1
        count <- count + 1
        
        # if you haven't shown all the images yet
        if(count<=length(images)){
            # show the next image
            output$Stimulus <- renderUI(tags$img(src=images[image_order[count]][[1]][1],height=150,width=150))}
        else{
            # otherwise end the experiment and show the finished panel
            hide("experiment")
            show("finished")
        }
    })
    
    # when the user presses submit
    observeEvent(input$Submit, {
        # add their text input for the Country to their results, and save this as answer
        answer <- c(results,input$Country)
        # write this as a new row in the google sheet
        sheet_append(data.frame(t((data.frame(answer)))),ss=sheet_ID)
        show("submitted")
        hide("finished")
    })
    
    # function for when a user enters something into the 'Other' field
    observeEvent(input$Other, {
        if(!is.null(input$Other) && input$Other != "")
            # update the radio buttons to include their new 'other' category and select the radio
            # button for that category
            updateRadioButtons(session, "Choice", choices = c(labels, input$Other), 
                               selected = input$Other)})
    

 }

shinyApp(ui=ui,server=server)