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

### 9.メール受信時にDKIM検証を行うwrapperをダウンロード
オリジナルのqmail-queueはリネームしてwrapperからキックされるようにする
```sh
~~mv /var/qmail/bin/qmail-queue /var/qmail/bin/qmail-queue.orig~~
~~wget -q -O /var/qmail/bin/qmail-queue --no-check-certificate https://github.com/corokada/return-qmail/raw/master/qmail-queue~~
~~chown qmailq.qmail qmail-queue~~
~~chmod 711 /var/qmail/bin/qmail-queue~~
~~chmod u+s /var/qmail/bin/qmail-queue~~
```

### 10.DKIM署名用の秘密鍵を保存するディレクトリを作成
```sh
mkdir -p /usr/local/etc/domainkeys
ln -s /usr/local/etc/domainkeys /etc/domainkeys
```

### 11.DKIM署名用の秘密鍵を作成するShellをダウンロード
```sh
wget -q -O /root/dkim_keygen.sh --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkim_keygen.sh
chmod +x /root/dkim_keygen.sh
```

### 12.秘密鍵を作成
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

### 13.TXTレコード作成

対象ドメインにTXTレコードを追加する（※テストモードで実施するために「t=y;」を付けておく）
```sh
#BIND
default._domainkey      IN      TXT     "k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
_adsp._domainkey        IN      TXT     "dkim=unknown"
#VALUE-DOMAIN
txt default._domainkey k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN...
txt _adsp._domainkey dkim=unknown
```

### 14.送信テスト

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

### 15.受信テスト

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

### 16.DKIMのテストモードを外す

TXTレコードから「t=y;」削除する

### 17.以上
