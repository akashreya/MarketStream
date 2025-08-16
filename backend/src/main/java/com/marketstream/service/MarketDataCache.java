package com.marketstream.service;

import com.marketstream.model.MarketData;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class MarketDataCache {
    @Autowired(required = false)
    private RedisTemplate<String, MarketData> redisTemplate;
    // Fallback in-memory cache if Redis is not available
    private final ConcurrentHashMap<String, MarketData> inMemoryCache = new ConcurrentHashMap<>();
    private static final String CACHE_KEY_PREFIX = "market:data:";
    private static final Duration CACHE_EXPIRY = Duration.ofMinutes(5);

    public void cacheMarketData(MarketData marketData) {
        String cacheKey = CACHE_KEY_PREFIX + marketData.getSymbol();
        if (redisTemplate != null) {
            try {
                redisTemplate.opsForValue().set(cacheKey, marketData, CACHE_EXPIRY);
            } catch (Exception e) {
                // Fallback to in-memory cache
                inMemoryCache.put(marketData.getSymbol(), marketData);
            }
        } else {
            inMemoryCache.put(marketData.getSymbol(), marketData);
        }
    }

    public MarketData getMarketData(String symbol) {
        String cacheKey = CACHE_KEY_PREFIX + symbol;
        if (redisTemplate != null) {
            try {
                MarketData cached = redisTemplate.opsForValue().get(cacheKey);
                if (cached != null) {
                    return cached;
                }
            } catch (Exception e) {
                // Fallback to in-memory cache
            }
        }
        return inMemoryCache.get(symbol);
    }

    public void clearCache() {
        if (redisTemplate != null) {
            try {
                redisTemplate.getConnectionFactory().getConnection().flushDb();
            } catch (Exception e) {
                // Ignore
            }
        }
        inMemoryCache.clear();
    }
}