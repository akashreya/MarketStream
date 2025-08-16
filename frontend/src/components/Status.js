import React from "react";

const Status = ({ connectionStatus }) => (
  <div className={`connection-status ${connectionStatus}`}>
    <i
      className={`fas ${
        connectionStatus === "connected"
          ? "fa-wifi"
          : connectionStatus === "connecting"
          ? "fa-spinner fa-spin"
          : "fa-wifi-slash"
      }`}
    ></i>
    {connectionStatus === "connected"
      ? "Connected"
      : connectionStatus === "connecting"
      ? "Connecting..."
      : "Disconnected"}
  </div>
);

export default Status;
