import React from "react";

const Controls = ({
  connect,
  disconnect,
  loadInitialData,
  clearData,
  isConnected,
}) => (
  <div className="controls">
    <button className="control-button" onClick={connect} disabled={isConnected}>
      <i className="fas fa-play"></i> Connect
    </button>
    <button
      className="control-button"
      onClick={disconnect}
      disabled={!isConnected}
    >
      <i className="fas fa-stop"></i> Disconnect
    </button>
    <button className="control-button" onClick={loadInitialData}>
      <i className="fas fa-refresh"></i> Refresh
    </button>
    <button className="control-button" onClick={clearData}>
      <i className="fas fa-trash"></i> Clear
    </button>
  </div>
);

export default Controls;
