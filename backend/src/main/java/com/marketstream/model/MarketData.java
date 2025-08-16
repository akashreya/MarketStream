package com.marketstream.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public class MarketData {
    private String symbol;
    private BigDecimal price;
    private BigDecimal bidPrice;
    private BigDecimal askPrice;
    private long volume;
    private BigDecimal change;
    private BigDecimal changePercent;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime timestamp;

    public MarketData() {
    }

    public MarketData(String symbol, BigDecimal price, BigDecimal bidPrice,
            BigDecimal askPrice, long volume, LocalDateTime timestamp) {
        this.symbol = symbol;
        this.price = price;
        this.bidPrice = bidPrice;
        this.askPrice = askPrice;
        this.volume = volume;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public String getSymbol() {
        return symbol;
    }

    public void setSymbol(String symbol) {
        this.symbol = symbol;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public BigDecimal getBidPrice() {
        return bidPrice;
    }

    public void setBidPrice(BigDecimal bidPrice) {
        this.bidPrice = bidPrice;
    }

    public BigDecimal getAskPrice() {
        return askPrice;
    }

    public void setAskPrice(BigDecimal askPrice) {
        this.askPrice = askPrice;
    }

    public long getVolume() {
        return volume;
    }

    public void setVolume(long volume) {
        this.volume = volume;
    }

    public BigDecimal getChange() {
        return change;
    }

    public void setChange(BigDecimal change) {
        this.change = change;
    }

    public BigDecimal getChangePercent() {
        return changePercent;
    }

    public void setChangePercent(BigDecimal changePercent) {
        this.changePercent = changePercent;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return "MarketData{" +
                "symbol='" + symbol + '\'' +
                ", price=" + price +
                ", bidPrice=" + bidPrice +
                ", askPrice=" + askPrice +
                ", volume=" + volume +
                ", change=" + change +
                ", changePercent=" + changePercent +
                ", timestamp=" + timestamp +
                '}';
    }
}