# utilities
Random utilities free to use

## tls-checker.sh

`tls-checker.sh` is a small shell utility to validate TLS/SSL certificate status for hostnames (or host:port). It reports expiry, validity, and expiration days, and exits non-zero when a certificate is near expiration or invalid.

### Usage

- Basic check for default HTTPS port 443:

  `./tls-checker.sh example.com`

- Custom port check:

  `./tls-checker.sh example.com 8443`

- Typical CI usage with threshold values:

  `./tls-checker.sh example.com 443 30`  # warns when cert expires in <= 30 days

### Description

1. Connects to the target host and port using OpenSSL.
2. Extracts certificate expiry date and remaining days.
3. Outputs a pass/warn/fail style status line.
4. Returns 0 if valid, 1 if expired/invalid, 2 on internal error.

Add your own values and scripts around it for monitoring, alerting, or automated certificate renewal workflows.

