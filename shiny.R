## connect to Redis
library(rredis)
library(treemap)
library(highcharter)
library(shiny)
library(data.table)
library(ggplot2)
library(dplyr)
redisConnect()

ui <- fluidPage(
  titlePanel("Cryptocurrency trades"),
  sidebarLayout(
    sidebarPanel(uiOutput("symbolSelectorRadio")),
    mainPanel(tableOutput("tradesTable"),
              plotOutput("tradesPlot"),
              highchartOutput('treemap', height = '800px'))
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
    rbindlist(trades)
  })

  output$treemap <- renderHighchart({
    tm <- treemap(trades()[symbol==input$symbolSelector], index = c('symbol'),
                  vSize = 'N', vColor = 'color',
                  type = 'value', draw = FALSE)
    N <- sum(symbols()$N)
    hc_title(hctreemap(tm, animation = FALSE),
             text = sprintf('Transactions (N=%s)', N))
  })
  
  output$tradesPlot <- renderPlot({
   plot(iris)
    
    
     # trades() %>%
 #    rbindlist(trades)[symbol=="ETHUSDT"]
      
  #    ggplot(rbindlist(trades)[symbol=="ETHUSDT"], aes(x = trade_timestamp, y = price)) +
   #   geom_line() +
  #    labs(y = "Price", x = "") +
  #    theme_minimal()
  })
})
shinyApp(ui = ui, server = server, options = list(port = 8080))