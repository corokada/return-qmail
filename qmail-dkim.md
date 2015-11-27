# return-qmail

## �R���e���c

* [Enable DKIM/Domainkeys](#0enable-dkimdomainkeys)

## 0.Enable DKIM/Domainkeys

qmail��DKIM�ɑΉ�������

### 1.�O�����

* qmail���C���X�g�[���ς�

### 2.perl��DKIM���W���[�����C���X�g�[��

yum�ł������ƃC���X�g�[��(cpan�ł�OK)
```sh
yum -y install perl-Mail-DKIM
or
cpanm Mail::DKIM
```

### 3.libdomainkeys���C���X�g�[��

�\�[�X�R���p�C���ŃC���X�g�[��
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

### 4.libdkim���C���X�g�[��

�\�[�X�R���p�C���ŃC���X�g�[��
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

### 5.DKIM�����E���؃X�N���v�g���_�E�����[�h
perl�X�N���v�g���_�E�����[�h
```sh
wget -q -O /var/qmail/bin/dkimsign.pl --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkimsign.pl
chmod +x /var/qmail/bin/dkimsign.pl
chgrp qmail /var/qmail/bin/dkimsign.pl
wget -q -O /var/qmail/bin/dkimverify.pl --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkimverify.pl
chmod +x /var/qmail/bin/dkimverify.pl
chgrp qmail /var/qmail/bin/dkimverify.pl
```
DKIM���؂ׂ̈�MX���R�[�h�Ɏw�肳��Ă��郁�[���T�[�o�[���ɏ���������
```sh
sed -i -e "s/example.com/`hostname`/" /var/qmail/bin/dkimverify.pl
or
sed -i -e "s/example.com/hogehoge.jp/" /var/qmail/bin/dkimverify.pl
```

### 6.DKIM����������ۂ̍�ƃf�B���N�g�����쐬
```sh
mkdir -p /var/domainkeys
chown qmailr:qmail /var/domainkeys
chmod 0700 /var/domainkeys
```

### 7.DKIM���؂�����ۂ̍�ƃf�B���N�g�����쐬
```sh
mkdir -p /var/domainkeys-verify
chown root.root /var/domainkeys-verify
chmod 0700 /var/domainkeys-verify
```

### 8.���[�����M����DKIM�������s��wrapper���_�E�����[�h
�I���W�i����qmail-remote�̓��l�[������wrapper����L�b�N�����悤�ɂ���
```sh
mv /var/qmail/bin/qmail-remote /var/qmail/bin/qmail-remote.orig
wget -q -O /var/qmail/bin/qmail-remote --no-check-certificate https://github.com/corokada/return-qmail/raw/master/qmail-remote
chown root:qmail /var/qmail/bin/qmail-remote
chmod 0755 /var/qmail/bin/qmail-remote
```

### 9.���[����M����DKIM���؂��s��wrapper���_�E�����[�h
�I���W�i����qmail-queue�̓��l�[������wrapper����L�b�N�����悤�ɂ���
```sh
mv /var/qmail/bin/qmail-queue /var/qmail/bin/qmail-queue.orig
wget -q -O /var/qmail/bin/qmail-queue --no-check-certificate https://github.com/corokada/return-qmail/raw/master/qmail-queue
chown qmailq.qmail qmail-queue
chmod 711 /var/qmail/bin/qmail-queue
chmod u+s /var/qmail/bin/qmail-queue
```

### 10.DKIM�����p�̔閧����ۑ�����f�B���N�g�����쐬
```sh
mkdir -p /usr/local/etc/domainkeys
ln -s /usr/local/etc/domainkeys /etc/domainkeys
```

### 11.DKIM�����p�̔閧�����쐬����Shell���_�E�����[�h
```sh
wget -q -O /root/dkim_keygen.sh --no-check-certificate https://github.com/corokada/return-qmail/raw/master/dkim_keygen.sh
chmod +x /root/dkim_keygen.sh
```

### 12.�閧�����쐬
DKIM�����p�̔閧�����쐬
```sh
/root/dkim_keygen.sh [�h���C����]
```
���s����
```sh
[�h���C����] DNS records adding sample
default._domainkey      IN      TXT     "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
_adsp._domainkey        IN      TXT     "dkim=unknown"
```

### 13.TXT���R�[�h�쐬

�Ώۃh���C����TXT���R�[�h��ǉ�����i���e�X�g���[�h�Ŏ��{���邽�߂Ɂut=y;�v��t���Ă����j
```sh
#BIND
default._domainkey      IN      TXT     "k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
_adsp._domainkey        IN      TXT     "dkim=unknown"
#VALUE-DOMAIN
txt default._domainkey k=rsa; t=y; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN...
txt _adsp._domainkey dkim=unknown
```

### 14.���M�e�X�g

�Ώۂ̃h���C�����烁�[����Gmail/yahoo���[�����ɑ��M�����āA���b�Z�[�W�\�[�X�Ɉȉ�������΁A�������ł��Ă���
```sh
#Gmail
Authentication-Results: mx.google.com;
       spf=pass (google.com: domain of ���[���A�h���X designates �T�[�o�[IP as permitted sender) smtp.mailfrom=���[���A�h���X;
       dkim=pass (test mode) header.i=@�h���C��
#Yahoo���[��
Received-SPF: pass (���[���T�[�o�[��: domain of ���[���A�h���X designates 54.64.79.211 as permitted sender) receiver=���[���T�[�o�[��; client-ip=�T�[�o�[IP; envelope-from=���[���A�h���X;
Authentication-Results: mta706.mail.djm.yahoo.co.jp  from=�h���C��; domainkeys=pass (ok); dkim=pass (ok); header.i=@�h���C��
```

### 15.��M�e�X�g

Gmail/yahoo���[������Ώۃh���C���̃��[���A�h���X�ɑ��M�����āA�ȉ�������΁ADKIM���؂��ł��Ă���
```sh
#Gmail
X-DKIM-Originator: xxx@gmail.com
X-DKIM-Policy-Detail: dk_sender=accept; dkim_author=accept;
  dkim_ADSP=accept
Authentication-Results: ���[���T�[�o�[��; dkim=pass
  header.i=@gmail.com; domainkeys=none
#Yahoo���[��
X-DKIM-Originator: xxx@yahoo.co.jp
X-DKIM-Policy-Detail: dk_sender=accept; dkim_author=accept;
  dkim_ADSP=accept
Authentication-Results: ���[���T�[�o�[��; dkim=pass
  header.i=@yahoo.co.jp; domainkeys=pass
  header.i=xxx@yahoo.co.jp
```

### 16.DKIM�̃e�X�g���[�h���O��

TXT���R�[�h����ut=y;�v�폜����

### 17.�ȏ�
