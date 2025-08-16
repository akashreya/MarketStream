import React from "react";

const formatTime = (seconds) => {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`;
};

const Stats = ({ stats, symbolsArray }) => (
  <div className="stats-panel">
    <h3>
      <i className="fas fa-chart-bar"></i> Statistics
    </h3>
    <div className="stats-grid">
      <div className="stat-item">
        <div className="stat-value">{stats.totalUpdates}</div>
        <div className="stat-label">Total Updates</div>
      </div>
      <div className="stat-item">
        <div className="stat-value">{symbolsArray.length}</div>
        <div className="stat-label">Active Symbols</div>
      </div>
      <div className="stat-item">
        <div className="stat-value">{formatTime(stats.connectedTime)}</div>
        <div className="stat-label">Connected Time</div>
      </div>
      <div className="stat-item">
        <div className="stat-value">{stats.lastUpdate || "N/A"}</div>
        <div className="stat-label">Last Update</div>
      </div>
    </div>
  </div>
);

export default Stats;
