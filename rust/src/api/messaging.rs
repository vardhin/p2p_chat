use serde::{Serialize, Deserialize};
use std::net::SocketAddr;
use std::time::{SystemTime, UNIX_EPOCH};

/// Message types for P2P communication
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MessageType {
    /// Initial handshake to establish connection
    Handshake,
    /// Acknowledge handshake
    HandshakeAck,
    /// Keep-alive/heartbeat
    Ping,
    /// Keep-alive response
    Pong,
    /// Text message
    Text,
    /// Connection close
    Close,
}

/// P2P Message structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct P2PMessage {
    pub msg_type: String,
    pub sender_id: String,
    pub timestamp: u64,
    pub sequence_num: u32,
    pub payload: Vec<u8>,
}

impl P2PMessage {
    /// Create a new message
    pub fn new(
        msg_type: MessageType,
        sender_id: String,
        sequence_num: u32,
        payload: Vec<u8>,
    ) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        P2PMessage {
            msg_type: format!("{:?}", msg_type),
            sender_id,
            timestamp,
            sequence_num,
            payload,
        }
    }

    /// Serialize message to bytes
    pub fn to_bytes(&self) -> Result<Vec<u8>, String> {
        bincode::serialize(self).map_err(|e| e.to_string())
    }

    /// Deserialize message from bytes
    pub fn from_bytes(data: &[u8]) -> Result<Self, String> {
        bincode::deserialize(data).map_err(|e| e.to_string())
    }
}

/// Connection state for a peer
#[derive(Debug, Clone, PartialEq)]
pub enum ConnectionState {
    /// Not connected
    Disconnected,
    /// Attempting to connect
    Connecting,
    /// Connected and ready
    Connected,
    /// Connection failed
    Failed,
}

/// Represents an active P2P connection
#[derive(Debug, Clone)]
pub struct P2PConnection {
    pub peer_id: String,
    pub local_addr: SocketAddr,
    pub remote_addr: SocketAddr,
    pub state: ConnectionState,
    pub last_ping: u64,
    pub sequence_num: u32,
}

impl P2PConnection {
    pub fn new(peer_id: String, local_addr: SocketAddr, remote_addr: SocketAddr) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        P2PConnection {
            peer_id,
            local_addr,
            remote_addr,
            state: ConnectionState::Disconnected,
            last_ping: timestamp,
            sequence_num: 0,
        }
    }

    /// Increment sequence number
    pub fn next_sequence(&mut self) -> u32 {
        self.sequence_num = self.sequence_num.wrapping_add(1);
        self.sequence_num
    }

    /// Check if connection needs keep-alive
    pub fn needs_keepalive(&self, timeout_secs: u64) -> bool {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        (now - self.last_ping) > timeout_secs
    }
}

/// UDP hole punching configuration
#[derive(Debug, Clone)]
pub struct HolePunchConfig {
    /// Number of punch attempts
    pub punch_attempts: usize,
    /// Delay between attempts in milliseconds
    pub punch_delay_ms: u64,
    /// Timeout for establishing connection in seconds
    pub connection_timeout: u64,
    /// Keep-alive interval in seconds
    pub keepalive_interval: u64,
}

impl Default for HolePunchConfig {
    fn default() -> Self {
        HolePunchConfig {
            punch_attempts: 5,
            punch_delay_ms: 100,
            connection_timeout: 10,
            keepalive_interval: 30,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_handshake_message(sender_id: String) -> Result<Vec<u8>, String> {
    let msg = P2PMessage::new(
        MessageType::Handshake,
        sender_id,
        0,
        vec![],
    );
    msg.to_bytes()
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_text_message(
    sender_id: String,
    sequence_num: u32,
    text: String,
) -> Result<Vec<u8>, String> {
    let msg = P2PMessage::new(
        MessageType::Text,
        sender_id,
        sequence_num,
        text.into_bytes(),
    );
    msg.to_bytes()
}

#[flutter_rust_bridge::frb(sync)]
pub fn parse_message(data: Vec<u8>) -> Result<(String, String, u64, String), String> {
    let msg = P2PMessage::from_bytes(&data)?;
    
    let payload_str = if msg.msg_type == "Text" {
        String::from_utf8(msg.payload).unwrap_or_default()
    } else {
        String::new()
    };

    Ok((msg.sender_id, msg.msg_type, msg.timestamp, payload_str))
}
