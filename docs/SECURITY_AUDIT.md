# Security Audit Checklist

## Automated Verifications
- [ ] TLS Handshake rejects untrusted certificates (`test/security/tls_rejection_test.dart`)
- [ ] Confession content is encrypted before Isar commit (`test/security/confession_encryption_test.dart`)
- [ ] App correctly strips PII (16-digit cards, emails) from accessibility logs

## Manual Validations before v1.0
- [ ] Extract the APK and verify obfuscation mappings (`flutter build apk --obfuscate`).
- [ ] Run `adb pull` on a physical device without root to ensure `/data/data/com.example.kero_space/` is inaccessible.
- [ ] Validate that the Rive overlay obscures the app completely when taking a break.
- [ ] Ensure Windows MSIX package does not bundle dev environment variables.

## Future Hardening
- Implement root/jailbreak detection.
- Implement Android keystore-backed encryption keys instead of user PIN derivation.
