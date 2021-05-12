
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

# The line below (drive_auth()) is used to authenticate your google account. Uncomment it and run the app ONCE, then check if the token 
# has been stored inside the .secrets folder, after that just comment out the line again (or it will ask you to sign in every time you run the app)

# drive_auth() # Authenticate to produce the token in the cache folder

# Tell gargle to search the token in the secrets folder and to look
# for an auth given to a certain email (enter your email linked to googledrive!)

drive_auth(cache = ".secrets", email = "YOUREMAIL@gmail.com")
gs4_auth(token = drive_token())

## 2. Make google sheet

# You only need to make the google sheet once, so uncomment the line below and run it in your console to make the google sheet, then comment it out again

# ss <- gs4_create("SurveyData")

# Run the code below in your console to get the sheet ID

# ss[1]

# Copy and paste the sheet ID from the console, storing it in the variable sheet_ID (replace the XXXXXXs here with your sheet ID)

sheet_ID <- "XXXXXXXXXXXXXXXXXXXXX"

# Congratulations, now this shiny app will be able to write to your google sheet!

### CODE FOR THE APP ITSELF

# Make a vector to store the image links
images <-  c(
  "https://www.brides.com/thmb/jfyHBWikMeTVowZL68mp3vW1lEA=/1197x1388/filters:fill(auto,1)/aef-a1eb0550df2645e581844a61585422ac.png",
  "https://cdn.valio.fi/mediafiles/48ec6532-3015-4a25-a0dc-c1f8078decf0/1600x1200-recipe-data/4x3/fodelsedagstarta-med-hallon-och-blabar.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Raspberry_tart.jpg/1200px-Raspberry_tart.jpg",
  "https://tmbidigitalassetsazure.blob.core.windows.net/rms3-prod/attachments/37/1200x1200/exps6086_HB133235C07_19_4b_WEB.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/f/fa/Freshly_baked_gingerbread_-_Christmas_2004.jpg",
  "https://files.allas.se/uploads/sites/25/2020/04/citronkaka-med-glasyr-2-700x920-1280.jpg",
  "https://s3.amazonaws.com/finecooking.s3.tauntonclud.com/app/uploads/2017/04/18182727/051054w-Dodge-Lemon-Tart-main.jpg",
  "https://imageresizer.static9.net.au/tPvl31oEOzRCSBjPofR2I8J-Od8=/1200x675/https%3A%2F%2Fprod.static9.net.au%2F_%2Fmedia%2Fnetwork%2Fimages%2F2019%2F01%2F06%2F11%2F43%2Fbiscuits.jpg",
  "https://d2rfo6yapuixuu.cloudfront.net/h65/h7c/8857136431134/07310960016403.jpg_master_axfood_400",
  "https://upload.wikimedia.org/wikipedia/commons/2/2b/SemlaFlickr.jpg",
  "https://www.thespruceeats.com/thmb/LztCwx-RV2XEcA9MuOG5Oqf7D44=/1606x1070/filters:fill(auto,1)/quick-cinnamon-rolls-3053776-81543bd7548c4b7fa95b8c51aaec316d.jpg",
  "https://cookinglsl.com/wp-content/uploads/2016/10/apple-pull-apart-bread-2-1.jpg",
  "https://tmbidigitalassetsazure.blob.core.windows.net/rms3-prod/attachments/37/1200x1200/exps9018_FB153741B05_27_4b.jpg",
  "https://images.immediate.co.uk/production/volatile/sites/30/2020/08/brioche-597b5f8.jpg",
  "https://files.allas.se/uploads/sites/31/2014/10/langpanna.jpg"
)

# Name the links so you know what image they refer to
names(images) <- c(
  "Wedding cake",
  "Birthday cake",
  "Raspberry tart",
  "Apple pie",
  "Gingerbread biscuits",
  "Lemon cake",
  "Lemon tart",
  "Oreos",
  "Wienerbröd",
  "Semla",
  "Cinammon scroll",
  "Apple pullapart",
  "Round pullapart",
  "Brioche",
  "Raspberry slice"
)

# I have hardcoded the links and images into the app, because that makes it load quicker than if you (e.g.) had this information in a csv file and read it from the csv file, but you can also do that if you have a lot of stimuli. Just try to make your csv file have as few columns as possible.

# Make the first row in the google sheet these names (plus an extra column for the person's country). 
# You only need to uncomment this and do this once.

# sheet_append(data.frame(t((data.frame(c(names(images),'Country'))))),ss=sheet_ID)

# create a vector of the names of the images in a random order -- this is used to randomise the order of the presentation of stimuli between participants
image_order <- sample(names(images))

# make a list of labels for your stimuli (these will be the options that people choose to describe them)
labels <- c("cake","tart","pie","biscuit","pastry","bun","bread")

# create the user interface
ui <- fluidPage(
    # use shinyjs in order to have hidden elements
    useShinyjs(),
    mainPanel(
        titlePanel("Baked goods survey"),
        # enclose stuff you want to treat as one element to hide and show at different points in the experiment in a div()
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
    onclick("Participate", {
        show("experiment")
        hide("instructions")
        # show the first image in image_order. Images contains the actual links to the images
        # and we use the name of the image (in image-order) as the key to access the image link
        # stored under that name in images. We need to use [[1]] instead of [1] at the end because using [1] will
        # return the name of the image as well as its link, but we only want the link
        output$Stimulus <- renderUI(tags$img(src=images[image_order[1]][[1]],height=150,width=150))
    })
    
    # make a variable to store the users choices of labels for the different images
    # we start with a vector of the right length full of numbers, and replace the numbers
    # with the users choices of labels as the experiment proceeds
    # we do this rather than using an empty vector, because we want to store their answers in the location
    # in the vector that matches the location of the column in the google sheet (since the images are presented in a 
    # random order that won't match their order in the google sheet)
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
            output$Stimulus <- renderUI(tags$img(src=images[image_order[count]][[1]],height=150,width=150))}
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
        # write this as a new row in the google sheet. Annoyingly, sheet_append only accepts a dataframe as input, so you have to convert the transposed vector 
        # (otherwise it will put the answers as one column instead of one row) to a dataframe
        sheet_append(as.data.frame(t(answer)),ss=sheet_ID)
        show("submitted")
        hide("finished")
    })
    
    # function for when a user enters something into the 'Other' field
    observeEvent(input$Other, {
        if(input$Other != ""){
            # update the radio buttons to include their new 'other' category and select the radio
            # button for that category
            updateRadioButtons(session, "Choice", choices = c(labels, input$Other), 
                               selected = input$Other)}
    })
    

 }

shinyApp(ui=ui,server=server)
