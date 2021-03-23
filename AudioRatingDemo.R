
### A DEMO OF HOW TO RUN A SIMILAR EXPERIMENT BUT WITH AUDIO FILES INSTEAD OF IMAGES
### AND IT'S A RATING TASK INSTEAD OF MULTIPLE CHOICE

library(shiny)
library(shinyjs)

## For simplicity, this doesn't write to google sheets.
## See the main app.R for how to do that.



# Make a vector to store the links to the sound files
sounds <- c(
    "https://upload.wikimedia.org/wikipedia/commons/9/99/Ja-nihongo.ogg",
    "https://upload.wikimedia.org/wikipedia/commons/e/e3/Sv-svenska.ogg",
    "https://upload.wikimedia.org/wikipedia/commons/9/97/Turkce.ogg"
)

# Name the links so you know what image they refer to
names(sounds) <- c("Japanese","Swedish","Turkish")

# create a vector of the names of the audio files in a random order 
sound_order <- sample(names(sounds))

# create the user interface
ui <- fluidPage(
    # use shinyjs in order to have hidden elements
    useShinyjs(),
    mainPanel(
        titlePanel("Rating audio files"),
        # enclose stuff you want to treat as one element 
        # to hide and show at different points in the experiment in a div()
        div(id="instructions",
            h4("Click participate if you want to rate some audio files."),
            actionButton("Participate","Participate")),
        # the hidden function hides a div when the application starts up
        # add code in the server to show it when the user reaches a certain point
        # in the experiment
        hidden(div(id="experiment",
                   h4("How English does this sound?"),
                   uiOutput("Stimulus"),
                   sliderInput("Choice",label=div(style='width:300px;', 
                                                  div(style='float:left;', 'not very english'), 
                                                  div(style='float:right;', 'very english')), 
                                           min=0,max=6,value=3,width='300px'),
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
        output$Stimulus <- renderUI(
            
            tags$audio(controls="controls",
                       tags$source(src=sounds[sound_order[1]][[1]][1],type="audio/ogg")
                )
            )
    })
    
    results <- c(1:length(sounds))
    
    count <- 1
    
    onclick("Next",{

        # work out where in the results vector to store the person's response to the image.
        # match() returns the index of a given value (the image name at image_order[count]) in 
        # a given vector (in this case, names(images)). We want to store the results in the same
        # order that we have the names for the images in the header of the google sheet, so that
        # they are in the right columns when we write the results to the google sheet. 
        
        results_index<-match(sound_order[count],names(sounds))
        
        # store the users input (their choice of label) in the right place in the results vector
        results[results_index]<-input$Choice
        
        # increase the image count by 1
        count <- count + 1
        
        # if you haven't shown all the images yet
        if(count<=length(sounds)){
            # show the next sound
            output$Stimulus <- renderUI(
                tags$audio(controls="controls",
                           tags$source(src=sounds[sound_order[count]][[1]][1],type="audio/ogg")
                )
            )}
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
        print(answer)
        show("submitted")
        hide("finished")
    })

 }

shinyApp(ui=ui,server=server)