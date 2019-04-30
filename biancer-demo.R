library(rJava)
library(AWR.Kinesis)
library(botor)

records <- kinesis_get_records('crypto', 'eu-west-1')

kin

str(records)
records[1]

library(jsonlite)
fromJSON(records[1])

a <- redisMGet(redisKeys('symbol:*'))
b <- redisMGet(redisKeys('trades:*'))

symbols_to_save <- c('ETHUSDT', 'LTCUSDT,', 'NEOUSDT', 'BTCUSDT', 'BNBUSDT')

dt <- rbindlist(lapply(records[records != '\r\n'], fromJSON))
str(dt)
setnames(dt, 'a', 'seller_id')
setnames(dt, 'b', 'buyer_id')
setnames(dt, 'E', 'event_timestamp')
## Unix timestamp / Epoch (number of seconds since Jan 1, 1970): https://www.epochconverter.com
dt[, event_timestamp := as.POSIXct(event_timestamp / 1000, origin = '1970-01-01')]
setnames(dt, 'q', 'quantity')
setnames(dt, 'p', 'price')
setnames(dt, 's', 'symbol')
setnames(dt, 't', 'trade_id')
setnames(dt, 'T', 'trade_timestamp')
dt[, trade_timestamp := as.POSIXct(trade_timestamp / 1000, origin = '1970-01-01')]
str(dt)

for (id in grep('_id', names(dt), value = TRUE)) {
  dt[, (id) := as.character(get(id))]  
}
str(dt)

library(binancer)
binance_coins_prices()

dt[, .N, by = symbol]
dt[symbol=='ETHUSDT']
dt[, from := substr(symbol, 1, 3)]
dt <- merge(dt, binance_coins_prices(), by.x = 'from', by.y = 'symbol', all.x = TRUE, all.y = FALSE)
dt[, value := as.numeric(quantity) * usd]
dt[, sum(value)]