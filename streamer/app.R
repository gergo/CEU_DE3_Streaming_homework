#!/usr/bin/Rscript

library(logger)
library(AWR.Kinesis)
library(jsonlite)
library(data.table)
library(rredis)

symbols_to_save <- c('ETHUSDT', 'LTCUSDT,', 'NEOUSDT', 'BTCUSDT', 'BNBUSDT')
save_all_symbols <- FALSE # set to FALSE to only save <CRYPTO>USD pairs -> much faster

process_record <- function(record) {
  symbol <- fromJSON(record)$s
  # only process <CRYPTO>USD pairs
  
  if (save_all_symbols | symbol %in% symbols_to_save) {
    log_info(paste('Found 1 transaction on', symbol))
    redisIncr(paste('symbol', symbol, sep = ':'))
    
    # parse record and updte names
    dt <- rbindlist(lapply((record), fromJSON))
    setnames(dt, 'a', 'seller_id')
    setnames(dt, 'b', 'buyer_id')
    setnames(dt, 'E', 'event_timestamp')
    dt[, event_timestamp := as.POSIXct(event_timestamp / 1000, origin = '1970-01-01')]

    setnames(dt, 'q', 'quantity')
    dt[, quantity := as.numeric(quantity)]

    setnames(dt, 'p', 'price')
    dt[, price := as.numeric(price)]

    setnames(dt, 's', 'symbol')
    setnames(dt, 't', 'trade_id')
    setnames(dt, 'T', 'trade_timestamp')
    dt[, trade_timestamp := as.POSIXct(trade_timestamp / 1000, origin = '1970-01-01')]
    dt[,c("m", "M", "e"):=NULL]
    dt[,volume:=price*quantity]
    
    # append to past trades stored in Redis
    redis_key <- paste0('trades:',symbol)
    trades <- redisGet(redis_key)
    trades <- rbind(dt, trades)
    redisSet(redis_key, trades)
  }
}

redis_purge <- function() {
  keys <- redisKeys('*')
  if (!is.null(keys)) {
    redisDelete(keys)
  }
}

kinesis_consumer(
  initialize = function() {
    log_info('Initializing Kinesis consumer')
    redisConnect(nodelay = FALSE)
    log_info('Connected to Redis')
    redis_purge()
  },
  
  processRecords = function(records) {
    log_info(paste('Received', nrow(records), 'records from Kinesis'))
    for (record in records$data) {
      process_record(record)
    }
  },
  
  updater = list(
    list(1/6, function() {
      log_info('Checking overall counters')
      symbols <- redisMGet(redisKeys('symbol:*'))
      log_info(paste(sum(as.numeric(symbols)), 'records processed so far'))
    })),
  
  shutdown = function(){
    log_info('Shutting down')
  },
  
  checkpointing = 1,
  logfile = 'app.log')