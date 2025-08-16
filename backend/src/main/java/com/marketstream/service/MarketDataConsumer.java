package com.marketstream.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.marketstream.model.MarketData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class MarketDataConsumer {
    private static final Logger logger = LoggerFactory.getLogger(MarketDataConsumer.class);
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    @Autowired
    private MarketDataCache cacheService;

    @KafkaListener(topics = "${app.kafka.topic.market-data}", groupId = "marketstream-consumer-group")
    public void consumeMarketData(@Payload String message,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            Acknowledgment acknowledgment) {
        try {
            MarketData marketData = objectMapper.readValue(message, MarketData.class);
            // Cache the latest market data
            cacheService.cacheMarketData(marketData);
            // Send to WebSocket subscribers
            messagingTemplate.convertAndSend("/topic/market-data/" + marketData.getSymbol(), marketData);
            messagingTemplate.convertAndSend("/topic/market-data/all", marketData);
            logger.debug("Processed market data for symbol: {} from partition: {} at offset: {}",
                    key, partition, offset);
            acknowledgment.acknowledge();
        } catch (JsonProcessingException e) {
            logger.error("Failed to deserialize market data message: {}", message, e);
            // In production, you might want to send to a dead letter queue
            acknowledgment.acknowledge();
        } catch (Exception e) {
            logger.error("Error processing market data message: {}", message, e);
            // Don't acknowledge on processing error to retry
        }
    }
}