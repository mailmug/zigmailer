
# zigmailer

Create custom SMTP servers on the fly.


## Configuration

#### How to start?

Download the repository
```
git clone git@github.com:mailmug/zigmailer.git
```

```zig
zig build run
```

## How To Test

Execute the following command

```
curl  \
  --url 'smtp://localhost:2525' \
  --user 'username@gmail.com:password' \
  --mail-from 'username@gmail.com' \
  --mail-rcpt 'john@example.com' \
  --upload-file testmail.txt
```



## Badges

 

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)



## Feedback

If you have any feedback, please reach out to us at info@mailmug.com

