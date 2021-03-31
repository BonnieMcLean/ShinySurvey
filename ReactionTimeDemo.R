
### A DEMO OF HOW TO COLLECT REACTION TIMES, USING THE AUDIO FILE EXAMPLES

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
  
    # make a vector to store the RTs
    RTs <- c(1:length(sounds))
    
    # make a reactive variable to store the current timestamps (begin and end time)
    current_timestamps <- reactiveVal(NULL)

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
        
        
        # make a vector with the start time appended to the current timestamps
        start_time <- append(current_timestamps(),Sys.time())
        # update the current timestamps to be that
        current_timestamps(start_time)
        
        
    })
    
    results <- c(1:length(sounds))
    
    count <- 1
    
    onclick("Next",{
      
        ## Make a vector with the end time added to the current_timestamps() [which now has the start time]
        all_times <- append(current_timestamps(),Sys.time())
        
        
        # Work out reaction time for previous trial, in milliseconds
        RT <- as.numeric(difftime(all_times[2],all_times[1],units="secs"))*1000
        
        # empty the current_timestamps list
        current_timestamps(NULL)
        
        # Set a new start time for the next trial
        start_time <- append(current_timestamps(),Sys.time())
        current_timestamps(start_time)

        # work out where in the results vector to store the person's response to the image.
        # match() returns the index of a given value (the image name at image_order[count]) in 
        # a given vector (in this case, names(images)). We want to store the results in the same
        # order that we have the names for the images in the header of the google sheet, so that
        # they are in the right columns when we write the results to the google sheet. 
        
        results_index<-match(sound_order[count],names(sounds))
        
        # store the users input (their choice of label) in the right place in the results vector
        results[results_index]<-input$Choice
        
        # also store their reaction time in the appropriate place in the RT vector
        
        RTs[results_index] <- RT
        
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
        # Record their responses, RTs (which will be in the same order as their responses), and country
        answer <- c(results,RTs,input$Country)
        print(answer)
        show("submitted")
        hide("finished")
    })

 }

shinyApp(ui=ui,server=server)