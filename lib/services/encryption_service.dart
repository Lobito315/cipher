import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'secure_storage_service.dart';

class EncryptionService {
  final _secureStorage = SecureStorageService();
  final _x25519 = X25519();
  final _chacha = Chacha20.poly1305Aead();

  static const String _keyPrivateKey = 'cipher_identity_private_key';
  static const String _keyPublicKey = 'cipher_identity_public_key';

  /// Ensures the user has an identity key pair. Derived deterministically from Master Password.
  Future<void> initIdentityKeys(String password, String email) async {
    // We derive a deterministic seed for the identity keys using the master password and email (as salt)
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 50000,
      bits: 256,
    );
    
    // Custom salt to differentiate from vault key
    final salt = utf8.encode("cipher_identity_v1_$email");
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    
    final seed = await secretKey.extractBytes();
    final keyPair = await _x25519.newKeyPairFromSeed(seed);
    final privBytes = await keyPair.extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey();
    
    await _secureStorage.writeRaw(_keyPrivateKey, base64Encode(privBytes));
    await _secureStorage.writeRaw(_keyPublicKey, base64Encode(pubKey.bytes));
  }

  Future<String?> getPublicKey() async {
    return await _secureStorage.readRaw(_keyPublicKey);
  }

  /// Derives a shared secret using Diffie-Hellman with another user's public key
  Future<SecretKey> deriveSharedSecret(String remotePublicKeyBase64) async {
    final privBase64 = await _secureStorage.readRaw(_keyPrivateKey);
    if (privBase64 == null) throw Exception("Identity keys not initialized");

    final privBytes = base64Decode(privBase64);
    final remotePubBytes = base64Decode(remotePublicKeyBase64);

    final localKeyPair = await _x25519.newKeyPairFromSeed(privBytes);
    final remotePublicKey = SimplePublicKey(
      remotePubBytes,
      type: KeyPairType.x25519,
    );

    return await _x25519.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: remotePublicKey,
    );
  }

  /// Encrypts a message using ChaCha20-Poly1305 and a shared secret
  Future<String> encryptMessage(String message, SecretKey secretKey) async {
    final clearText = utf8.encode(message);
    final secretBox = await _chacha.encrypt(clearText, secretKey: secretKey);
    // Combine nonce + cipherText + mac for transport
    return base64Encode(secretBox.concatenation());
  }

  /// Decrypts a message using ChaCha20-Poly1305 and a shared secret
  Future<String> decryptMessage(
    String encryptedBase64,
    SecretKey secretKey,
  ) async {
    final combined = base64Decode(encryptedBase64);
    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: _chacha.nonceLength,
      macLength: _chacha.macAlgorithm.macLength,
    );
    final clearBytes = await _chacha.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(clearBytes);
  }

  /// Generates cryptographically secure random bytes
  Future<List<int>> generateRandomBytes(int length) async {
    final key = await _x25519.newKeyPair();
    final bits = await key.extractPrivateKeyBytes();
    return bits.sublist(0, length);
    // Note: Cryptography package doesn't have a direct 'randomBytes' but creating a new keypair
    // and taking its private bytes is a standard way to get secure entropy.
  }

  /// Derives a 256-bit vault key from a Master Password
  Future<List<int>> deriveVaultKey(String masterPassword, String salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: utf8.encode(salt),
    );
    return await secretKey.extractBytes();
  }

  /// Low-level encryption for local storage (using a simple derived key)
  Future<String> encryptLocal(String data, List<int> localKey) async {
    final secretKey = SecretKey(localKey);
    return await encryptMessage(data, secretKey);
  }

  Future<String> decryptLocal(String encrypted, List<int> localKey) async {
    final secretKey = SecretKey(localKey);
    return await decryptMessage(encrypted, secretKey);
  }
}
