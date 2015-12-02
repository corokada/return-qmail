# return-qmail

## コンテンツ

* [Enable DKIM/Domainkeys](#0enable-dkimdomainkeys)

## 0.Enable DKIM/Domainkeys

qmailをDKIMに対応させる

### 1.前提条件

* qmailがインストール済み

### 2.perlのDKIMモジュールをインストール

yumでさくっとインストール(cpanでもOK)
```sh
yum -y install perl-Mail-DKIM
or
cpanm Mail::DKIM
```

### 3.libdomainkeysをインストール

ソースコンパイルでインストール
```sh
cd /usr/local/src
wget -q -O libdomainkeys-0.69.tar.gz --no-check-certificate https://github.com/corokada/return-qmail/raw/master/libdomainkeys-0.69.tar.gz
tar -xzf libdomainkeys-0.69.tar.gz
cd libdomainkeys-0.69
echo -lresolv > dns.lib
make
install -m 644 libdomainkeys.a /usr/local/lib
install -m 644 domainkeys.h dktrace.h /usr/local/include
install -m 755 dknewkey /usr/local/bin
```
```sh
$ sha256sum libdomainkeys-0.69.tar.gz
7e10dd7c8d20d8fde181a2550c77e241c27750ec74e0b8859e2664136d7aa21e  libdomainkeys-0.69.tar.gz
```

### 4.libdkimをインストール

ソースコンパイルでインストール
```sh
cd /usr/local/src
wget -q -O libdkim-1.0.19.zip --no-check-certificate https://github.com/corokada/return-qmail/raw/master/libdkim-1.0.19.zip
wget -q -O libdkim-1.0.19-linux.patch --no-check-certificate https://github.com/corokada/return-qmail/raw/master/libdkim-1.0.19-linux.patch
wget -q -O libdkim-1.0.19-extra-options.patch --no-check-certificate https://github.com/corokada/return-qmail/raw/master/libdkim-1.0.19-extra-options.patch
unzip libdkim-1.0.19.zip
cd libdkim/src
patch -p2 < ../../libdkim-1.0.19-linux.patch
patch -p2 < ../../libdkim-1.0.19-extra-options.patch
make
make install
```
```sh
$ sha256sum libdkim-1.0.19.zip libdkim-1.0.19-linux.patch libdkim-1.0.19-extra-options.patch
1935c88ea3d053ec2039114d900ac9eb5962adee10e0ec163777dfa5f3bd4eed  libdkim-1.0.19.zip
a008f94e34864c90070336cb36b92f606bcc5262c72e5004c4c46d5b014eb339  libdkim-1.0.19-linux.patch
039769a4a39c1420111c69987bee21205e2e05fb35cf134a7c03f10888c4f2b9  libdkim-1.0.19-extra-options.patch
```

### 5.DKIM署名・検証スクリプトをダウンロード
perlスクリプトをダウンロード
```sh
wget -q -O /var/qmail/bin/dkimsign.pl --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkimsign.pl
chmod +x /var/qmail/bin/dkimsign.pl
chgrp qmail /var/qmail/bin/dkimsign.pl
wget -q -O /var/qmail/bin/dkimverify.pl --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkimverify.pl
chmod +x /var/qmail/bin/dkimverify.pl
chgrp qmail /var/qmail/bin/dkimverify.pl
```
```sh
$ sha256sum /var/qmail/bin/dkimsign.pl /var/qmail/bin/dkimverify.pl
3c420eff7978ee47379d19b42bcbc224b909aeea0c70759bf98d16e9375e0c97  /var/qmail/bin/dkimsign.pl
4fc2f0f866eb6fa1c60705d342e122b89e5e43855b17549fffd6e68a98736aca  /var/qmail/bin/dkimverify.pl
```

DKIM検証の為にMXレコードに指定されているメールサーバー名に書き換える
```sh
sed -i -e "s/example.com/`hostname`/" /var/qmail/bin/dkimverify.pl
or
sed -i -e "s/example.com/hogehoge.jp/" /var/qmail/bin/dkimverify.pl
```

### 6.DKIM署名をする際の作業ディレクトリを作成
```sh
mkdir -p /var/domainkeys
chown qmailr:qmail /var/domainkeys
chmod 0700 /var/domainkeys
```

### 7.DKIM検証をする際の作業ディレクトリを作成
```sh
mkdir -p /var/domainkeys-verify
chown root.root /var/domainkeys-verify
chmod 0700 /var/domainkeys-verify
```

### 8.メール送信時にDKIM署名を行うwrapperをダウンロード
オリジナルのqmail-remoteはリネームしてwrapperからキックされるようにする
```sh
mv /var/qmail/bin/qmail-remote /var/qmail/bin/qmail-remote.orig
wget -q -O /var/qmail/bin/qmail-remote --no-check-certificate https://github.com/corokada/return-qmail/raw/master/qmail-remote
chown root:qmail /var/qmail/bin/qmail-remote
chmod 0755 /var/qmail/bin/qmail-remote
```
```sh
$ sha256sum /var/qmail/bin/qmail-remote
eafeb48367a6c90ecde404d5e801c46a5db24dbc5f3387ccbf9e2fe39652b4b7  /var/qmail/bin/qmail-remote
```

### 9.メール受信時にDKIM検証を行うwrapperをダウンロード
```sh
wget -q -O /var/qmail/bin/qmail-dkimverify --no-check-certificate https://raw.githubusercontent.com/corokada/return-qmail/master/qmail-dkimverify
chown root:qmail /var/qmail/bin/qmail-dkimverify
chmod 0755 /var/qmail/bin/qmail-dkimverify
```
```sh
$ sha256sum /var/qmail/bin/qmail-dkimverify
7fd23e24fac0ce988f301d73b15484322fd130a04df6da931c8a556056eea889  /var/qmail/bin/qmail-dkimverify
```

### 10.QMAILQUEUEを利用できるようにする
QMAILQUEUEを利用してqmail-dkimverifyを呼び出しDKIM検証を行う為、qmailをリコンパイルする
```sh
cd /usr/local/src
wget -q -O qmailqueue-patch --no-check-certificate https://raw.githubusercontent.com/corokada/return-qmail/master/qmailqueue-patchhttps://raw.githubusercontent.com/corokada/return-qmail/master/qmailqueue-patch
cd qmail-1.03
patch -p1 < ../qmailqueue-patch
rm -f `cat TARGETS`
make
mv /var/qmail/bin/qmail-smtpd /var/qmail/bin/qmail-smtpd.orig
cp qmail-smtpd /var/qmail/bin/qmail-smtpd
chown root.qmail /var/qmail/bin/qmail-smtpd
chmod 711 /var/qmail/bin/qmail-smtpd
```
```sh
$ sha256sum qmailqueue-patch
52e82aaa34e9f1308b063cc986a701f67e161662e9f789bb12af03a381530f94  qmailqueue-patch
```
qmailのrestartは必須
```sh
/etc/init.d/qmail restart
```

### 11.QMAILQUEUEを設定する
修正をして、定義ファイルを更新する
```sh
vi /path/to/tcp.smtp
```
```sh
:allow
  ↓↓↓↓↓
:allow,QMAILQUEUE="/var/qmail/bin/qmail-dkimverify"
```
定義ファイルを更新
```sh
/usr/local/bin/tcprules /path/to/tcp.smtp.cdb /path/to/tcp.smtp.tmp < /path/to/tcp.smtp
```

### 12.DKIM署名用の秘密鍵を保存するディレクトリを作成
```sh
mkdir -p /usr/local/etc/domainkeys
ln -s /usr/local/etc/domainkeys /etc/domainkeys
```

### 13.DKIM署名用の秘密鍵を作成するShellをダウンロード
```sh
wget -q -O /root/dkim_keygen.sh --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkim_keygen.sh
chmod +x /root/dkim_keygen.sh
```

### 14.秘密鍵を作成
DKIM署名用の秘密鍵を作成
```sh
/root/dkim_keygen.sh [ドメイン名]
```
実行結果
```sh
[ドメイン名] DNS records adding sample
default._domainkey      IN      TXT     "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
_adsp._domainkey        IN      TXT     "dkim=unknown"
```

### 15.TXTレコード作成

対象ドメインにTXTレコードを追加する（※テストモードで実施するために「t=y;」を付けておく）
```sh
#BIND
default._domainkey      IN      TXT     "k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
_adsp._domainkey        IN      TXT     "dkim=unknown"
#VALUE-DOMAIN
txt default._domainkey k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN...
txt _adsp._domainkey dkim=unknown
```

### 16.送信テスト

対象のドメインからメールをGmail/yahooメール宛に送信をして、メッセージソースに以下があれば、署名ができている
```sh
#Gmail
Authentication-Results: mx.google.com;
       spf=pass (google.com: domain of メールアドレス designates サーバーIP as permitted sender) smtp.mailfrom=メールアドレス;
       dkim=pass (test mode) header.i=@ドメイン
#Yahooメール
Received-SPF: pass (メールサーバー名: domain of メールアドレス designates 54.64.79.211 as permitted sender) receiver=メールサーバー名; client-ip=サーバーIP; envelope-from=メールアドレス;
Authentication-Results: mta706.mail.djm.yahoo.co.jp  from=ドメイン; domainkeys=pass (ok); dkim=pass (ok); header.i=@ドメイン
```

### 17.受信テスト

Gmail/yahooメールから対象ドメインのメールアドレスに送信をして、以下があれば、DKIM検証ができている
```sh
#Gmail
X-DKIM-Originator: xxx@gmail.com
X-DKIM-Policy-Detail: dk_sender=accept; dkim_author=accept;
  dkim_ADSP=accept
Authentication-Results: メールサーバー名; dkim=pass
  header.i=@gmail.com; domainkeys=none
#Yahooメール
X-DKIM-Originator: xxx@yahoo.co.jp
X-DKIM-Policy-Detail: dk_sender=accept; dkim_author=accept;
  dkim_ADSP=accept
Authentication-Results: メールサーバー名; dkim=pass
  header.i=@yahoo.co.jp; domainkeys=pass
  header.i=xxx@yahoo.co.jp
```

### 18.DKIMのテストモードを外す

TXTレコードから「t=y;」削除する

### 19.以上
