import React from "react";

const MarketGrid = ({
  symbolsArray,
  marketData,
  updatedSymbols,
  formatPrice,
  getChangeClass,
  getChangeIcon,
  formatChange,
}) => (
  <div className="market-grid">
    {symbolsArray.map((symbol) => {
      const data = marketData[symbol];
      const isUpdated = updatedSymbols.has(symbol);

      return (
        <div
          key={symbol}
          className={`market-card ${isUpdated ? "updated pulse" : ""}`}
        >
          <div className="symbol">
            <i className="fas fa-chart-line"></i>
            {data.symbol}
          </div>

          <div className="price">{formatPrice(data.price)}</div>

          <div className={`change ${getChangeClass(data.change)}`}>
            <i className={getChangeIcon(data.change)}></i>
            {formatChange(data.change, data.changePercent)}
          </div>

          <div className="market-details">
            <div className="detail-item">
              <div className="detail-label">Bid</div>
              <div className="detail-value">{formatPrice(data.bidPrice)}</div>
            </div>
            <div className="detail-item">
              <div className="detail-label">Ask</div>
              <div className="detail-value">{formatPrice(data.askPrice)}</div>
            </div>
            <div className="detail-item">
              <div className="detail-label">Volume</div>
              <div className="detail-value">{data.volume.toLocaleString()}</div>
            </div>
            <div className="detail-item">
              <div className="detail-label">Spread</div>
              <div className="detail-value">
                {formatPrice(data.askPrice - data.bidPrice)}
              </div>
            </div>
          </div>

          <div className="timestamp">
            <i className="fas fa-clock"></i>
            {new Date(data.timestamp).toLocaleTimeString()}
          </div>
        </div>
      );
    })}
  </div>
);

export default MarketGrid;
