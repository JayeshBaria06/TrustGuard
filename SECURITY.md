# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.5.x   | :white_check_mark: |
| 1.4.x   | :white_check_mark: |
| < 1.4   | :x:                |

## Reporting a Vulnerability

We take the security of TrustGuard seriously. If you believe you have found a security vulnerability, please report it to us responsibly.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please use one of these methods:

1. **GitHub Security Advisories** (Preferred): Report via [GitHub's private vulnerability reporting](https://github.com/MasuRii/TrustGuard/security/advisories/new)
2. **Email**: Contact the maintainers directly through their GitHub profiles

### What to Include

Please include as much of the following information as possible:

- **Type of vulnerability** (e.g., data exposure, authentication bypass, injection, etc.)
- **Full paths of source file(s)** related to the issue
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact assessment** — what an attacker could achieve
- **Any suggested fixes** (optional but appreciated)

### What to Expect

| Timeline | Action |
| -------- | ------ |
| 48 hours | We will acknowledge receipt of your report |
| 7 days   | We will confirm the vulnerability and provide an initial assessment |
| 30 days  | We aim to release a fix for confirmed vulnerabilities |

We will keep you informed of our progress throughout the process.

## Security Measures

TrustGuard implements the following security measures:

### Data Protection

- **Offline-First**: All data is stored locally on your device
- **No Cloud Sync**: Your financial data never leaves your device unless you explicitly export it
- **Secure Storage**: Sensitive data (PIN hash, security preferences) stored using platform-secure storage

### Authentication

- **PIN Lock**: Optional app lock with salted + hashed PIN (SHA-256)
- **Biometric Authentication**: Fingerprint/Face ID support via platform APIs
- **Export Protection**: Optional requirement to authenticate before exporting data

### Privacy

- **No Analytics**: We don't collect any usage data
- **No Network Requests**: The app works entirely offline
- **Transparent Data**: Full JSON backup lets you inspect all stored data

## Security Best Practices for Users

1. **Enable App Lock**: Set up a PIN or biometric lock in Settings
2. **Regular Backups**: Export backups to a secure location
3. **Keep Updated**: Always use the latest version for security patches
4. **Device Security**: Ensure your device has a screen lock enabled

## Acknowledgments

We appreciate the security research community's efforts in helping keep TrustGuard secure. Reporters who responsibly disclose vulnerabilities will be acknowledged in our release notes (unless they prefer to remain anonymous).
