import React, { useState, useEffect, useRef } from "react";
import ReactDOM from "react-dom/client";
import "sockjs-client";
import "stompjs";
import "./styles.css";
import Status from "./components/Status";
import Controls from "./components/Controls";
import Stats from "./components/Stats";
import MarketGrid from "./components/MarketGrid";

const MarketStream = () => {
  const [marketData, setMarketData] = useState({});
  const [connectionStatus, setConnectionStatus] = useState("disconnected");
  const [isConnected, setIsConnected] = useState(false);
  const [stats, setStats] = useState({
    totalUpdates: 0,
    connectedTime: 0,
    lastUpdate: null,
  });
  const [updatedSymbols, setUpdatedSymbols] = useState(new Set());

  const stompClient = useRef(null);
  const connectTime = useRef(null);
  const intervalRef = useRef(null);

  const API_BASE_URL = process.env.NODE_ENV === 'production' 
    ? "https://marketstream.akashreya.space" 
    : "http://localhost:8090";
  const WS_URL = process.env.NODE_ENV === 'production' 
    ? "wss://marketstream.akashreya.space/ws" 
    : "http://localhost:8090/ws";

  useEffect(() => {
    loadInitialData();
    return () => {
      disconnect();
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  const loadInitialData = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/market-data/snapshots`);
      if (response.ok) {
        const snapshots = await response.json();
        const dataMap = {};
        snapshots.forEach((item) => {
          dataMap[item.symbol] = item;
        });
        setMarketData(dataMap);
      }
    } catch (error) {
      console.error("Failed to load initial data:", error);
    }
  };

  const connect = () => {
    if (isConnected) return;

    setConnectionStatus("connecting");

    const socket = new SockJS(WS_URL);
    stompClient.current = Stomp.over(socket);

    stompClient.current.connect(
      {},
      (frame) => {
        console.log("Connected: " + frame);
        setConnectionStatus("connected");
        setIsConnected(true);
        connectTime.current = Date.now();

        // Start connection time counter
        intervalRef.current = setInterval(() => {
          setStats((prev) => ({
            ...prev,
            connectedTime: Math.floor(
              (Date.now() - connectTime.current) / 1000
            ),
          }));
        }, 1000);

        // Subscribe to all market data
        stompClient.current.subscribe("/topic/market-data/all", (message) => {
          const data = JSON.parse(message.body);

          setMarketData((prev) => ({
            ...prev,
            [data.symbol]: data,
          }));

          setStats((prev) => ({
            ...prev,
            totalUpdates: prev.totalUpdates + 1,
            lastUpdate: new Date().toLocaleTimeString(),
          }));

          // Flash effect
          setUpdatedSymbols((prev) => new Set([...prev, data.symbol]));
          setTimeout(() => {
            setUpdatedSymbols((prev) => {
              const newSet = new Set(prev);
              newSet.delete(data.symbol);
              return newSet;
            });
          }, 500);
        });
      },
      (error) => {
        console.error("Connection error:", error);
        setConnectionStatus("disconnected");
        setIsConnected(false);
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
        }
      }
    );
  };

  const disconnect = () => {
    if (stompClient.current) {
      stompClient.current.disconnect();
      stompClient.current = null;
    }
    setConnectionStatus("disconnected");
    setIsConnected(false);
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
  };

  const clearData = () => {
    setMarketData({});
    setStats({
      totalUpdates: 0,
      connectedTime: 0,
      lastUpdate: null,
    });
    setUpdatedSymbols(new Set());
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2,
    }).format(price);
  };

  const formatChange = (change, changePercent) => {
    const sign = change >= 0 ? "+" : "";
    return `${sign}${formatPrice(change)} (${sign}${changePercent}%)`;
  };

  const getChangeClass = (change) => {
    if (change > 0) return "positive";
    if (change < 0) return "negative";
    return "neutral";
  };

  const getChangeIcon = (change) => {
    if (change > 0) return "fas fa-arrow-up";
    if (change < 0) return "fas fa-arrow-down";
    return "fas fa-minus";
  };

  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`;
  };

  const symbolsArray = Object.keys(marketData).sort();

  return (
    <div className="container">
      <div className="header">
        <h1>
          <i className="fas fa-chart-line"></i> MarketStream
        </h1>
        <p>Real-Time Market Data Streaming Platform</p>
        <Status connectionStatus={connectionStatus} />
      </div>

      <Controls
        connect={connect}
        disconnect={disconnect}
        loadInitialData={loadInitialData}
        clearData={clearData}
        isConnected={isConnected}
      />

      <Stats stats={stats} symbolsArray={symbolsArray} />

      {symbolsArray.length === 0 ? (
        <div className="loading">
          <div className="spinner"></div>
          <p>Loading market data...</p>
        </div>
      ) : (
        <MarketGrid
          symbolsArray={symbolsArray}
          marketData={marketData}
          updatedSymbols={updatedSymbols}
          formatPrice={formatPrice}
          getChangeClass={getChangeClass}
          getChangeIcon={getChangeIcon}
          formatChange={formatChange}
        />
      )}
    </div>
  );
};

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<MarketStream />);
