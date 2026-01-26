use bip39::{Mnemonic, Language};
use sha2::{Sha256, Digest};
use rand::Rng;

/// Generates a new 24-word BIP39 seed phrase for cryptographic identity
#[flutter_rust_bridge::frb(sync)]
pub fn generate_seed_phrase() -> String {
    // Generate 32 bytes of entropy (256 bits) for a 24-word mnemonic
    let mut entropy = [0u8; 32];
    rand::thread_rng().fill(&mut entropy);
    
    let mnemonic = Mnemonic::from_entropy_in(Language::English, &entropy)
        .expect("Failed to generate mnemonic");
    
    mnemonic.to_string()
}

/// Validates a seed phrase
#[flutter_rust_bridge::frb(sync)]
pub fn validate_seed_phrase(phrase: String) -> bool {
    Mnemonic::parse_in_normalized(Language::English, &phrase).is_ok()
}

/// Derives a deterministic seed from the mnemonic phrase
/// This can be used for key derivation
#[flutter_rust_bridge::frb(sync)]
pub fn derive_seed_from_phrase(phrase: String, passphrase: Option<String>) -> Result<Vec<u8>, String> {
    let mnemonic = Mnemonic::parse_in_normalized(Language::English, &phrase)
        .map_err(|e| format!("Invalid mnemonic: {}", e))?;
    
    let seed = mnemonic.to_seed(passphrase.unwrap_or_default().as_str());
    Ok(seed.to_vec())
}

/// Derives cryptographic keys from the seed phrase for various purposes
/// Returns a JSON string containing different key types (base64 encoded)
#[flutter_rust_bridge::frb(sync)]
pub fn derive_cryptographic_keys(seed_phrase: String) -> Result<String, String> {
    // Derive the master seed
    let seed_bytes = derive_seed_from_phrase(seed_phrase.clone(), None)?;
    
    // Derive different keys for different purposes
    let encryption_key = derive_key_for_purpose(&seed_bytes, "encryption");
    let signing_key = derive_key_for_purpose(&seed_bytes, "signing");
    let identity_key = derive_key_for_purpose(&seed_bytes, "identity");
    let network_key = derive_key_for_purpose(&seed_bytes, "network");
    
    // Create JSON response with base64 encoded keys
    let json_response = format!(
        r#"{{
  "encryption_key": "{}",
  "signing_key": "{}",
  "identity_key": "{}",
  "network_key": "{}",
  "key_format": "base64",
  "algorithm": "SHA256-HMAC"
}}"#,
        base64_encode(&encryption_key),
        base64_encode(&signing_key),
        base64_encode(&identity_key),
        base64_encode(&network_key),
    );
    
    Ok(json_response)
}

/// Derives a specific key for a given purpose using HKDF-like approach
fn derive_key_for_purpose(seed: &[u8], purpose: &str) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(seed);
    hasher.update(purpose.as_bytes());
    hasher.update(b"p2p_chat_key_derivation");
    hasher.finalize().to_vec()
}

/// Simple base64 encoding helper
fn base64_encode(data: &[u8]) -> String {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut result = String::new();
    let mut i = 0;
    
    while i < data.len() {
        let b1 = data[i];
        let b2 = if i + 1 < data.len() { data[i + 1] } else { 0 };
        let b3 = if i + 2 < data.len() { data[i + 2] } else { 0 };
        
        let n = ((b1 as u32) << 16) | ((b2 as u32) << 8) | (b3 as u32);
        
        result.push(alphabet.chars().nth(((n >> 18) & 0x3f) as usize).unwrap());
        result.push(alphabet.chars().nth(((n >> 12) & 0x3f) as usize).unwrap());
        
        if i + 1 < data.len() {
            result.push(alphabet.chars().nth(((n >> 6) & 0x3f) as usize).unwrap());
        } else {
            result.push('=');
        }
        
        if i + 2 < data.len() {
            result.push(alphabet.chars().nth((n & 0x3f) as usize).unwrap());
        } else {
            result.push('=');
        }
        
        i += 3;
    }
    
    result
}

/// Exports identity information in a structured format
#[flutter_rust_bridge::frb(sync)]
pub fn export_identity_data(seed_phrase: String, identity_name: String) -> Result<String, String> {
    // Validate seed phrase
    if !validate_seed_phrase(seed_phrase.clone()) {
        return Err("Invalid seed phrase".to_string());
    }
    
    // Derive keys
    let keys_json = derive_cryptographic_keys(seed_phrase.clone())?;
    
    // Create comprehensive identity export
    let export_data = format!(
        r#"{{
  "identity_name": "{}",
  "seed_phrase": "{}",
  "cryptographic_keys": {},
  "export_date": "{}",
  "version": "1.0"
}}"#,
        identity_name,
        seed_phrase,
        keys_json,
        "2024",
    );
    
    Ok(export_data)
}