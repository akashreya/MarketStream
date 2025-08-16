package com.marketstream.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.marketstream.model.MarketData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class MarketDataProducer {
    private static final Logger logger = LoggerFactory.getLogger(MarketDataProducer.class);
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    @Autowired
    private ObjectMapper objectMapper;
    @Value("${app.kafka.topic.market-data}")
    private String marketDataTopic;
    private final List<String> symbols = Arrays.asList(
            "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX", "TATAINFY", "RELIANCE");
    private final ConcurrentHashMap<String, BigDecimal> lastPrices = new ConcurrentHashMap<>();
    private final Random random = new Random();
    // Initialize with base prices
    {
        lastPrices.put("AAPL", new BigDecimal("150.00"));
        lastPrices.put("GOOGL", new BigDecimal("2800.00"));
        lastPrices.put("MSFT", new BigDecimal("300.00"));
        lastPrices.put("AMZN", new BigDecimal("3200.00"));
        lastPrices.put("TSLA", new BigDecimal("800.00"));
        lastPrices.put("META", new BigDecimal("250.00"));
        lastPrices.put("NVDA", new BigDecimal("450.00"));
        lastPrices.put("NFLX", new BigDecimal("400.00"));
        lastPrices.put("TATAINFY", new BigDecimal("25.00"));
        lastPrices.put("RELIANCE", new BigDecimal("2500.00"));
    }

    @Scheduled(fixedDelay = 1000) // Every second
    public void generateMarketData() {
        symbols.forEach(this::generateAndSendMarketData);
    }

    private void generateAndSendMarketData(String symbol) {
        try {
            MarketData marketData = generateMarketData(symbol);
            String json = objectMapper.writeValueAsString(marketData);
            CompletableFuture<SendResult<String, String>> future = kafkaTemplate.send(marketDataTopic, symbol, json);
            future.whenComplete((result, ex) -> {
                if (ex != null) {
                    logger.error("Failed to send market data for symbol: {}", symbol, ex);
                } else {
                    logger.debug("Market data sent successfully for symbol: {} at offset: {}",
                            symbol, result.getRecordMetadata().offset());
                }
            });
        } catch (JsonProcessingException e) {
            logger.error("Failed to serialize market data for symbol: {}", symbol, e);
        }
    }

    private MarketData generateMarketData(String symbol) {
        BigDecimal currentPrice = lastPrices.get(symbol);
        // Generate price change (-5% to +5%)
        double changePercent = (random.nextDouble() - 0.5) * 0.1; // -5% to +5%
        BigDecimal priceChange = currentPrice.multiply(BigDecimal.valueOf(changePercent));
        BigDecimal newPrice = currentPrice.add(priceChange).setScale(2, RoundingMode.HALF_UP);
        // Ensure price doesn't go below 1.00
        if (newPrice.compareTo(BigDecimal.ONE) < 0) {
            newPrice = BigDecimal.ONE;
        }
        lastPrices.put(symbol, newPrice);
        // Generate bid/ask spread (0.1% to 0.5%)
        BigDecimal spread = newPrice.multiply(BigDecimal.valueOf(random.nextDouble() * 0.004 + 0.001));
        BigDecimal bidPrice = newPrice.subtract(spread.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
        BigDecimal askPrice = newPrice.add(spread.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
        // Generate volume
        long volume = 1000 + random.nextInt(9000);
        MarketData marketData = new MarketData(symbol, newPrice, bidPrice, askPrice, volume, LocalDateTime.now());
        marketData.setChange(priceChange);
        marketData.setChangePercent(BigDecimal.valueOf(changePercent * 100).setScale(2, RoundingMode.HALF_UP));
        return marketData;
    }
}