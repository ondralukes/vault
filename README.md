# vault

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f414eaf5b6f545bca4c64914ef18a6b3)](https://app.codacy.com/manual/ondralukes/vault?utm_source=github.com&utm_medium=referral&utm_content=ondralukes/vault&utm_campaign=Badge_Grade_Dashboard)

App for encrypted messages
## :lock:Encryption
This app uses RSA (OAEP padding) with 2048-bit key and AES with 256-bit key
### Message format
* `0-16` IV
* `17` Padding length
* `17-x [encrypted]` Padding + message JSON
## :floppy_disk:Storage
Data are stored in MongoDB (defined in `src/server.js:8`).
## Features
|Feature|Web app|Flutter app|
|----|:----:|:----:|
|Signing up|:heavy_check_mark:|:heavy_check_mark:|
|Signing in|:heavy_check_mark:|:heavy_check_mark:|
|Creating vault|:heavy_check_mark:|:heavy_check_mark:|
|Sending messages|:heavy_check_mark:|:heavy_check_mark:|
|Adding member to vault|:heavy_check_mark:|:heavy_check_mark:|
|Leaving vault|:heavy_check_mark:|:heavy_check_mark:|
|Deleting vault|:x:|:x:|
|Notifications|:x:|Android only<br>(15 min interval)|
