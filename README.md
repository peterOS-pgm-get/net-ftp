# Net-FTP

A [PeterOS](https://github.com/Platratio34/peterOS) [pgm-get](https://github.com/peterOS-pgm-get/pgm-get) program

Install on PeterOS via:
```console
pgm-get install net-ftp
```

## Command

### `net-ftp help`:
Print CLI help

### `net-ftp list [remote]/[path]`:
List all files on the remote at path

### `net-ftp check [remote]/[path]`:
Check if file on the remote exits

### `net-ftp get [remote]/[path] [local path]`:
Get a file from the remote and place it at the local path

### `net-ftp push [remote]/[path] [local path]`:
Push a file to the remote from the local path

### `net-ftp host`:
Start an FTP fileserver from config

### `net-ftp unhost`:
Stop the FTP fileserver


## Program package: `_G.ftp`
[Documentation](https://github.com/peterOS-pgm-get/net-ftp/wiki)

### Classes: 
[`ftp.FTPConnection`](https://github.com/peterOS-pgm-get/net-ftp/wiki/FTPConnection)
[`ftp.FTPMount`](https://github.com/peterOS-pgm-get/net-ftp/wiki/FTPMount)