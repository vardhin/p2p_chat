# Cryptographic Keys Export Feature - Implementation Summary

## Overview
Added complete cryptographic key generation and export functionality to the P2P Chat application. Users can now generate, view, and export their cryptographic keys derived from their identity's seed phrase.

## Features Added

### 1. **Rust Backend - Key Derivation** (`rust/src/api/identity.rs`)

#### New Functions:

**`derive_cryptographic_keys(seed_phrase: String) -> Result<String, String>`**
- Derives four types of cryptographic keys from the seed phrase:
  - **Encryption Key**: Used for AES-256-GCM data encryption
  - **Signing Key**: Used for digital signatures and message authentication
  - **Identity Key**: Unique identifier for the user's profile
  - **Network Key**: Used for P2P network communications
- Returns a JSON response with all keys in base64 encoding
- Uses SHA256-HMAC for key derivation with domain separation
- Algorithm: SHA256-based HKDF-like approach for security

**`derive_key_for_purpose(seed: &[u8], purpose: &str) -> Vec<u8>`** (Private)
- Helper function that derives a specific key for a given purpose
- Uses HMAC-SHA256 with purpose-specific context
- Ensures different keys for different purposes

**`export_identity_data(seed_phrase: String, identity_name: String) -> Result<String, String>`**
- Comprehensive export function that bundles identity information
- Includes identity name, seed phrase, all cryptographic keys
- Returns structured JSON format
- Validates seed phrase before export

**`base64_encode(data: &[u8]) -> String`** (Private)
- Standard base64 encoding for key representation
- Compatible with standard base64 decoders

### 2. **Dart UI Layer - Crypto Keys Screen** (`lib/screens/crypto_keys_screen.dart`)

#### CryptoKeysScreen Widget
A comprehensive screen for managing cryptographic keys with the following features:

**Key Display:**
- Shows all 4 derived cryptographic keys
- Each key is in a dedicated card with copy-to-clipboard functionality
- Keys can be hidden/revealed via toggle switch for security
- Masked display (asterisks) when keys are hidden

**Key Management Features:**
- **Show/Hide Toggle**: Switch to reveal or mask keys
- **Copy to Clipboard**: Individual copy buttons for each key
- **Regenerate Keys**: Button to regenerate keys from seed phrase
- **Export All Keys**: Export all keys in a formatted text block

**Security UI Elements:**
- Orange warning banner at top with security notice
- Key information section explaining each key's purpose
- Disclaimer about never sharing keys with anyone
- Visual indicators (lock icons, color coding)

**Architecture:**
- Uses FutureBuilder to asynchronously load and derive keys
- Real-time error handling with SnackBar feedback
- Responsive design that works on all screen sizes
- Loading state with spinner during key generation

### 3. **Integration with Settings Screen** (`lib/screens/settings_screen.dart`)

#### Changes Made:
- Added import for `CryptoKeysScreen`
- Added new "Cryptographic Keys" option in the Identity section
- Uses FutureBuilder to check for current identity
- Navigates to CryptoKeysScreen when tapped
- Shows only when an identity is available

#### Updated UI:
```
Identity Section
├── View Seed Phrase
└── Cryptographic Keys (NEW)
    ├── Show/Hide Toggle
    ├── Encryption Key
    ├── Signing Key
    ├── Identity Key
    ├── Network Key
    └── Export Options
```

## Key Derivation Process

### Security Model:
1. **Base Derivation**: Uses BIP39 seed phrase as entropy source
2. **Purpose-Based Derivation**: Each key type has unique derivation path
3. **SHA256-HMAC**: Uses domain-separated HMAC for cryptographic strength
4. **Base64 Encoding**: Keys are base64-encoded for safe transmission/storage

### Key Types:

| Key Type | Purpose | Usage |
|----------|---------|-------|
| **Encryption Key** | Data protection | AES-256-GCM encryption |
| **Signing Key** | Message authentication | Digital signatures |
| **Identity Key** | Profile identification | User identifier in network |
| **Network Key** | P2P communication | Secure peer-to-peer messages |

## User Workflow

### To Export Keys:
1. Open **Settings**
2. Tap **Cryptographic Keys** (under Identity section)
3. Keys are automatically generated from current identity
4. Click **Show Keys** toggle to reveal key values
5. Choose export option:
   - **Copy Individual Key**: Click copy icon on each key card
   - **Export All Keys**: Click "Export All Keys" button
6. Keys are copied to clipboard as formatted text

### Security Best Practices:
- Keys are hidden by default (masked with asterisks)
- Users must explicitly toggle to reveal keys
- Warning message encourages secure storage
- Keys are never logged or stored in plain text
- Each session regenerates keys on demand

## Technical Details

### Dependencies:
- `flutter/services.dart`: Clipboard management
- `p2p_chat/utils/identity_manager.dart`: Identity retrieval
- `p2p_chat/src/rust/api/identity.dart`: Rust FFI bindings
- Dart Async: FutureBuilder for async operations

### Rust Dependencies:
- `sha2`: SHA256 hashing for key derivation
- `rand`: Random number generation
- `bip39`: Seed phrase validation
- `serde/bincode`: Serialization (existing)

### Error Handling:
- Invalid seed phrase validation before key generation
- Try-catch blocks for async operations
- User-friendly error messages via SnackBar
- Graceful degradation if keys can't be generated

## Testing Checklist

- [ ] Navigate to Settings > Cryptographic Keys
- [ ] Verify keys generate successfully from seed phrase
- [ ] Test Show/Hide toggle functionality
- [ ] Copy individual keys to clipboard
- [ ] Export all keys to clipboard
- [ ] Verify JSON format of exported keys
- [ ] Test with different identities
- [ ] Verify keys change when switching identities
- [ ] Check error handling (invalid seed phrase)
- [ ] Confirm regenerate button works
- [ ] Test on both iOS and Android

## Future Enhancements

1. **File Export**: Save keys to secure file format
2. **Key Encryption**: Encrypt exported keys with additional password
3. **QR Code**: Generate QR codes for key sharing
4. **Key Rotation**: Support key rotation on schedule
5. **Backup**: Integrated backup of cryptographic keys
6. **Multi-Device**: Sync keys across devices securely
7. **Hardware Integration**: Support for hardware wallets
8. **Key Recovery**: Emergency recovery procedures

## Security Considerations

### Current Implementation:
- Keys derived deterministically from seed phrase
- No hardcoded secrets
- Base64 encoding for safe display
- Clipboard operations are secure
- UI provides warnings about key protection

### Recommendations:
- Users should never screenshot keys
- Export keys only on secure devices
- Store exported keys in encrypted password managers
- Use hardware security modules for production
- Regular key rotation recommended
- Implement rate limiting for key export operations

## Code Examples

### Generating Keys (Dart):
```dart
final keysJson = await deriveCryptographicKeys(
  seedPhrase: identity.seedPhrase,
);
```

### Parsing Keys Response:
```dart
// Response includes JSON with base64-encoded keys:
{
  "encryption_key": "...",
  "signing_key": "...",
  "identity_key": "...",
  "network_key": "...",
  "key_format": "base64",
  "algorithm": "SHA256-HMAC"
}
```

## Files Modified/Created

### Created:
- `/lib/screens/crypto_keys_screen.dart` - Main crypto keys UI screen

### Modified:
- `/lib/screens/settings_screen.dart` - Added crypto keys navigation
- `/rust/src/api/identity.rs` - Added key derivation functions

### Dependencies Updated:
- None (all required crates already present in Cargo.toml)

## Build Status

✅ **Rust Build**: Successful (no warnings or errors)
✅ **Dart Compilation**: Successful
✅ **Flutter Dependencies**: All resolved
✅ **iOS Build**: Ready to test
✅ **Android Build**: Ready to test

## Summary

The cryptographic keys export feature is now fully integrated into the P2P Chat application. Users can:
- Generate cryptographic keys from their identity
- View and manage all key types
- Export keys for backup or sharing
- Toggle key visibility for security
- Copy keys individually or in bulk

This feature enhances the application's security model by giving users direct access to their cryptographic keys while maintaining security best practices through UI warnings and key masking.
