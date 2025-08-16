package com.marketstream.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class WebSocketController {
    private static final Logger logger = LoggerFactory.getLogger(WebSocketController.class);

    @MessageMapping("/subscribe")
    @SendTo("/topic/market-data/all")
    public String subscribe(String symbol) {
        logger.info("Client subscribed to symbol: {}", symbol);
        return "Subscribed to " + symbol;
    }
}