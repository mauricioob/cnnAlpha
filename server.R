library(keras)

server <- function(input, output, session) {
    
    inputData <- callModule(inputHandling, 'alpha')
    
    shinyjs::hide(selector = "a[data-value=benchmark]")
    shinyjs::hide(selector = "a[data-value=results]")
    
    hasDisorderInfo <- function(sequencesData) {
        # only checks the first sequence. If disorder information is present, when read it will be appended to the end of the sequence
        # we check if the second half contains only disorder characters
        firstSequenceDisInfo <- toString(subseq(sequencesData[1],nchar(sequencesData[1])/2+1))
        return(grepl("^[DdOo]+$", firstSequenceDisInfo))
    }
    
    observeEvent(inputData$predict(), {
        tryCatch({
            req(length(inputData$sequenceData()) != 0)
            
            tryCatch({
                shinyjs::hide(selector = "a[data-value=benchmark]")
                shinyjs::hide(selector = "a[data-value=results]")
                
                #gets sequence data
                sequencesData <- inputData$sequenceData()
                hasDisorderInfo <- hasDisorderInfo(sequencesData)
                
                #make predictions
                predictionResults <- predict(sequencesData, hasDisorderInfo, inputData$cnnModel(), inputData$edgeCorrection())
                
                #render plots
                sequencePlot <- callModule(sequencePlot, 'alpha', predictionResults, hasDisorderInfo)
                shinyjs::show(selector = "a[data-value=results]")
                
                #render benchmark
                if (hasDisorderInfo) {
                    actualValues <- predictionResults$actualValues
                    predictedValues <- predictionResults$predictionsWithClasses
                    confusionMatrix <- confusionMatrix(factor(predictedValues), factor(actualValues))
                    benchmark <- callModule(sequenceBenchmark, 'alpha', predictionResults, confusionMatrix)
                    shinyjs::show(selector = "a[data-value=benchmark]")
                }
                
                #updates screen
                updateTabItems(session, "tabs",
                               selected = "results")
            }, error = function(e) {
                sendSweetAlert(session, title = "Application error", text = paste("Please contact support team:\n\n", e), type = 'error',
                               btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
            })
        }, error = function(e) {
            sendSweetAlert(session, title = "Validation error", text = "Please make sure to enter at least one input sequence in fasta format", type = 'warning',
                           btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
        })
        
    })
    
    observeEvent(input$startHere, {
        #updates screen
        updateTabItems(session, "tabs",
                       selected = "inputData")
    })
    
    session$onSessionEnded(function() {
        print('session ends')
    })
    
    # info sidebar ----
    # add info sidebar to ui
    observeEvent(input$info_btn, {
        insertUI(selector = '.main-header', ui = div(id = 'info_block', infoContent()), 
                 where = 'afterEnd', immediate = TRUE)
    }, once = TRUE)
    
    # content of the info sidebar
    infoContent <- function() {
        tagList(
            h1('Help', style = 'font-weight: bold; font-size: 28px;'),
            tags$p("If you have an issue, please report it here."),
            actionButton('reportIssue', 'Report an issue', class = 'primary-nibr-btn', 
                         onclick = "window.open('https://github.com/mauricioob/shiny-pred/issues')")
        )
    }
    
    # show/hide info sidebar
    observeEvent(input$info_btn, {
        toggleCssClass(id = 'info_btn', class = 'selected_on_header', condition = {input$info_btn %% 2 != 0})
        toggleCssClass(id = 'info_block', class = 'opened-info-sidebar', condition = {input$info_btn %% 2 != 0})
    }, ignoreInit = TRUE)
}
