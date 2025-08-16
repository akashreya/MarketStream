package com.marketstream;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MarketStreamApplication {
    public static void main(String[] args) {
        SpringApplication.run(MarketStreamApplication.class, args);
    }
}