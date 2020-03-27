# vault

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f414eaf5b6f545bca4c64914ef18a6b3)](https://app.codacy.com/manual/ondralukes/vault?utm_source=github.com&utm_medium=referral&utm_content=ondralukes/vault&utm_campaign=Badge_Grade_Dashboard)

Node.js web app for encrypted notes and messages
## Encryption
This app uses RSA with 2048-bit key and AES with 256-bit key
### Message format
* `0-16` IV
* `17` Padding length
* `17-x` Padding + message JSON
## Storage
Data are stored in MongoDB (defined in `src/server.js:8`)
