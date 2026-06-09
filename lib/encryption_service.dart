import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static final _key = encrypt.Key.fromUtf8('my_super_secret_key_32_chars_long_'); 
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptText(String text) => _encrypter.encrypt(text, iv: _iv).base64;
  static String decryptText(String encryptedText) => _encrypter.decrypt64(encryptedText, iv: _iv);
}