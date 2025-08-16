package com.marketstream.controller;

import com.marketstream.model.MarketData;
import com.marketstream.service.MarketDataCache;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/market-data")
@CrossOrigin(originPatterns = "*")
public class MarketDataController {
    private static final Logger logger = LoggerFactory.getLogger(MarketDataController.class);
    @Autowired
    private MarketDataCache cacheService;
    private final List<String> availableSymbols = Arrays.asList(
            "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX", "TATAINFY", "RELIANCE");

    @GetMapping("/snapshot/{symbol}")
    public ResponseEntity<MarketData> getSnapshot(@PathVariable String symbol) {
        logger.info("Getting snapshot for symbol: {}", symbol);
        MarketData marketData = cacheService.getMarketData(symbol.toUpperCase());
        if (marketData != null) {
            return ResponseEntity.ok(marketData);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/symbols")
    public ResponseEntity<List<String>> getAvailableSymbols() {
        return ResponseEntity.ok(availableSymbols);
    }

    @GetMapping("/snapshots")
    public ResponseEntity<List<MarketData>> getAllSnapshots() {
        logger.info("Getting all snapshots for {} symbols", availableSymbols.size());
        List<MarketData> snapshots = availableSymbols.stream()
                .map(symbol -> {
                    try {
                        MarketData data = cacheService.getMarketData(symbol);
                        if (data == null) {
                            logger.debug("No cached data for symbol: {}, creating default data", symbol);
                            // Create default market data if nothing is cached
                            data = createDefaultMarketData(symbol);
                            cacheService.cacheMarketData(data);
                        }
                        return data;
                    } catch (Exception e) {
                        logger.error("Error getting data for symbol: {}", symbol, e);
                        return createDefaultMarketData(symbol);
                    }
                })
                .filter(data -> data != null)
                .collect(Collectors.toList());
        logger.info("Returning {} snapshots", snapshots.size());
        return ResponseEntity.ok(snapshots);
    }

    private MarketData createDefaultMarketData(String symbol) {
        // Create default market data with base prices
        java.math.BigDecimal basePrice = getBasePriceForSymbol(symbol);
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        MarketData data = new MarketData(symbol, basePrice, basePrice, basePrice, 1000L, now);
        data.setChange(java.math.BigDecimal.ZERO);
        data.setChangePercent(java.math.BigDecimal.ZERO);
        return data;
    }

    private java.math.BigDecimal getBasePriceForSymbol(String symbol) {
        switch (symbol) {
            case "AAPL": return new java.math.BigDecimal("150.00");
            case "GOOGL": return new java.math.BigDecimal("2800.00");
            case "MSFT": return new java.math.BigDecimal("300.00");
            case "AMZN": return new java.math.BigDecimal("3200.00");
            case "TSLA": return new java.math.BigDecimal("800.00");
            case "META": return new java.math.BigDecimal("250.00");
            case "NVDA": return new java.math.BigDecimal("450.00");
            case "NFLX": return new java.math.BigDecimal("400.00");
            case "TATAINFY": return new java.math.BigDecimal("25.00");
            case "RELIANCE": return new java.math.BigDecimal("2500.00");
            default: return new java.math.BigDecimal("100.00");
        }
    }

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("MarketStream is running");
    }
}