use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce, Key
};
use sha2::{Sha256, Digest};
use rand::RngCore;

/// Derives a 256-bit encryption key from seed phrase
fn derive_key_from_seed(seed_phrase: &str) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(seed_phrase.as_bytes());
    hasher.update(b"network_data_encryption"); // Domain separator
    let result = hasher.finalize();
    let mut key = [0u8; 32];
    key.copy_from_slice(&result);
    key
}

/// Encrypts data using AES-256-GCM with seed phrase
#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_network_data(data: String, seed_phrase: String) -> Result<Vec<u8>, String> {
    let key_bytes = derive_key_from_seed(&seed_phrase);
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);
    
    // Generate random nonce
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    // Encrypt
    let ciphertext = cipher.encrypt(nonce, data.as_bytes())
        .map_err(|e| format!("Encryption failed: {}", e))?;
    
    // Prepend nonce to ciphertext
    let mut result = nonce_bytes.to_vec();
    result.extend_from_slice(&ciphertext);
    
    Ok(result)
}

/// Decrypts data using AES-256-GCM with seed phrase
#[flutter_rust_bridge::frb(sync)]
pub fn decrypt_network_data(encrypted_data: Vec<u8>, seed_phrase: String) -> Result<String, String> {
    if encrypted_data.len() < 12 {
        return Err("Invalid encrypted data".to_string());
    }
    
    let key_bytes = derive_key_from_seed(&seed_phrase);
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);
    
    // Extract nonce and ciphertext
    let (nonce_bytes, ciphertext) = encrypted_data.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);
    
    // Decrypt
    let plaintext = cipher.decrypt(nonce, ciphertext)
        .map_err(|e| format!("Decryption failed: {}", e))?;
    
    String::from_utf8(plaintext)
        .map_err(|e| format!("Invalid UTF-8: {}", e))
}