use bip39::{Mnemonic, Language};
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