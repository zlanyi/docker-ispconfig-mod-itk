Dockerfile for ISPConfig on Debian Jessie
with 
- MariaDB database
- Apache2 Mod-ITK
- PHP5
- mod_security
- Roundcubemail
- Jailkit
- fail2ban
- Free SSL (Certbot)


Installed packages from Binaries:

rsyslog rsyslog-relp logrotate supervisor ssh openssh-server rsync nano vim-nox ntp ntpdate postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl apache2 apache2.2-common apache2-doc apache2-mpm-itk apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-xcache memcached libapache2-mod-passenger libapache2-mod-evasive libapache2-mod-security2 build-essential autoconf automake libtool flex bison debhelper binutils fail2ban

Installed packages from source:
- RoundCube 1.1.3
- Jailkit 2.19


Based on How to from Till Brehm: 

https://www.howtoforge.com/tutorial/perfect-server-debian-8-4-jessie-apache-bind-dovecot-ispconfig-3-1

Author: Zoltan Lanyi <zoltan.lanyi@gmail.com>

Date  : 06.07.2016