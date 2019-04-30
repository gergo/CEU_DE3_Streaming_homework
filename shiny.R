## connect to Redis
library(rredis)
redisConnect()

library(shiny)
library(data.table)
library(ggplot2)
library(dplyr)

ui <- fluidPage(
  titlePanel("Cryptocurrency trades"),
  sidebarLayout(
    sidebarPanel(uiOutput("symbolSelectorRadio")),
    mainPanel(tableOutput("tradesTable"),
              plotOutput("tradesPlot"))
    )
  )
  
server <- shinyServer(function(input, output, session) {
  getStaticSymbols <- function() {
    symbols <- redisMGet(redisKeys('symbol:*'))
    symbols <- data.table(
      symbol = sub('^symbol:', '', names(symbols)))    
    ## return
    symbols$symbol
  }
  staticSymbols <- getStaticSymbols()
  
  symbols <- reactive({
    ## auto-update every 2 seconds
    reactiveTimer(2000)()
    
    ## get frequencies
    symbols <- redisMGet(redisKeys('symbol:*'))
    symbols <- data.table(
      symbol = sub('^symbol:', '', names(symbols)),
      trade_count = as.numeric(symbols))
    
    ## return
    symbols
  })
  
  output$tradesTable <- renderTable({symbols()})
  
  output$symbolSelectorRadio <- renderUI({
    radioButtons("symbolSelector",
                 label = "Cryptocurrency:",
                 choices = as.list(staticSymbols))
  })
  
  trades <- reactive({
    ## auto-update every 2 seconds
    reactiveTimer(2000)()
    
    ## get frequencies
    trades <- redisMGet(redisKeys('trades:*'))
    rbindlist(trades)
  })

  output$tradesPlot <- renderPlot({
    # trades() %>%
    rbindlist(trades) %>%
      dplyr::filter(symbol=='ETHUSDT')
      ggplot(aes(x = event_timestamp, y = price)) +
      geom_line() +
      labs(title = "AAPL Line Chart", y = "Closing Price", x = "") + 
      theme_minimal()
  })
})
shinyApp(ui = ui, server = server, options = list(port = 8080))