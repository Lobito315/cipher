import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'secure_storage_service.dart';

class EncryptionService {
  final _secureStorage = SecureStorageService();
  final _x25519 = X25519();
  final _chacha = Chacha20.poly1305Aead();

  static const String _keyPrivateKey = 'cipher_identity_private_key';
  static const String _keyPublicKey = 'cipher_identity_public_key';

  /// Ensures the user has an identity key pair. Generates one if missing.
  Future<void> initIdentityKeys() async {
    // Keys are stored in secure storage as base64
    final storedPriv = await _secureStorage.readRaw(_keyPrivateKey);

    if (storedPriv == null) {
      final keyPair = await _x25519.newKeyPair();
      final privBytes = await keyPair.extractPrivateKeyBytes();
      final pubKey = await keyPair.extractPublicKey();
      final pubBytes = pubKey.bytes;

      await _secureStorage.writeRaw(_keyPrivateKey, base64Encode(privBytes));
      await _secureStorage.writeRaw(_keyPublicKey, base64Encode(pubBytes));
    }
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
