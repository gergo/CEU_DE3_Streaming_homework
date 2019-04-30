library(rredis)
library(binancer)

redisConnect()

store <- function(symbol) {
  print(paste('Looking up and storing', symbol))
  redisSet(paste('price', symbol, sep = ':'), 
           binance_klines(paste0(symbol, 'USDT'), interval = '1m', limit = 1)$close)
}

store('BTC')
store('ETH')

## list all keys with the "price" prefix and lookup the actual values
redisMGet(redisKeys('price:*'))


library(rredis)
redisConnect()

redisSet('price:BTC', binance_klines('BTCUSDT', interval = '1m', limit = 1)$close)
redisSet('price:ETH', binance_klines('ETHUSDT', interval = '1m', limit = 1)$close)

redisGet('price:BTC')
redisGet('price:ETH')

redisMGet(c('price:BTC', 'price:ETH'))