## connect to Redis
library(rredis)
library(treemap)
library(highcharter)
library(shiny)
library(data.table)
library(ggplot2)
library(dplyr)
library(DT)

redisConnect()

ui <- fluidPage(
  titlePanel("Cryptocurrency trades"),
  sidebarLayout(
    sidebarPanel(uiOutput("symbolSelectorRadio")),
    mainPanel(tableOutput("tradesTable"),
              plotOutput("tradesPlot"),
              tableOutput("selectedCryptoTrades") #,
              # DT::dataTableOutput("selectedTradesTable") #,
              # highchartOutput('tradesTreemap', height = '800px')
      )
    )
  )
  
server <- shinyServer(function(input, output, session) {
  getStaticSymbols <- function() {
    symbols <- redisMGet(redisKeys('symbol:*'))
    symbols <- data.table(symbol = sub('^symbol:', '', names(symbols)))    
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
      trade_count = as.numeric(symbols)
    )
    
    ## return
    symbols
  })
  
  output$tradesTable <- renderTable({
    transpose(symbols())
  })
  
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
    trades <- rbindlist(trades)
    
    # return
    trades
  })

  # output$tradesTreemap <- renderHighchart({
  #   df <- trades()[symbol==input$symbolSelector]
  #   df[, color := 1]
  #   df[symbol %in% df[order(-volume)][1:30, symbol], color := 2]
  #   tm <- treemap(df,
  #                 c('volume'),
  #                 vSize = 'volume',
  #                 vColor = 'color',
  #                 type = 'value',
  #                 palette="RdYlBu",
  #                 fun.aggregate="sum")
  #   volume <- sum(trades()$volume)
  #   hc_title(hctreemap(tm, animation = FALSE),
  #            text = sprintf('Transaction volume=%s', volume))
  # })
  
  output$tradesPlot <- renderPlot({
      ggplot(trades()[symbol==input$symbolSelector], aes(x = trade_timestamp, y = price)) +
      geom_line() +
      labs(y = "Price", x = "Time") +
      theme_minimal()
  })

  output$selectedCryptoTrades <- renderTable({
    trades()[symbol==input$symbolSelector][order(-volume)]
  })
  
  # output$selectedTradesTable = DT::renderDataTable({
  #   trades()[symbol==input$symbolSelector]
  # })
})
shinyApp(ui = ui, server = server, options = list(port = 8080))