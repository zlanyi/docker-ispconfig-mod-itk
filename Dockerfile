#
#
# Dockerfile for ISPConfig with MariaDB database and Apache2 Mod-ITK
#
# How to: https://www.howtoforge.com/tutorial/perfect-server-debian-8-4-jessie-apache-bind-dovecot-ispconfig-3-1
#
# Date  : 06.07.2016
# Author: Zoltan Lanyi <zoltan.lanyi@gmail.com>
#

FROM debian:jessie

MAINTAINER Zoltan Lanyi <zoltan.lanyi@gmail.com> version: 0.1.2

ENV DEBIAN_FRONTEND noninteractive

# --- 1 Update Your Debian Installation
ADD ./etc/apt/sources.list /etc/apt/sources.list
RUN apt-get -y update && apt-get -y upgrade

# --- 2 Reqs
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install rsyslog rsyslog-relp logrotate supervisor ssh openssh-server rsync nano vim-nox ntp ntpdate
RUN touch /var/log/cron.log
# Create the log file to be able to run tail
RUN touch /var/log/auth.log

# --- 3 Change The Default Shell
RUN echo "dash  dash/sh boolean no" | debconf-set-selections
RUN dpkg-reconfigure dash

# --- 4 Install Postfix, Dovecot, MySQL, phpMyAdmin, rkhunter, binutils
RUN echo 'mysql-server mysql-server/root_password password pass' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password pass' | debconf-set-selections
RUN echo 'mariadb-server mariadb-server/root_password password pass' | debconf-set-selections
RUN echo 'mariadb-server mariadb-server/root_password_again password pass' | debconf-set-selections
RUN apt-get -y install postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN service postfix restart
RUN service mysql restart

# --- 5 Install Amavisd-new, SpamAssassin And Clamav
RUN apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf
RUN service spamassassin stop
RUN systemctl disable spamassassin

# --- 6 Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, xcache and mcrypt
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password pass' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
RUN service mysql restart && apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-itk apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-xcache memcached libapache2-mod-passenger libapache2-mod-evasive libapache2-mod-security2
RUN a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers security2 && service apache2 restart

# --- 7 Free SSL
RUN mkdir /opt/certbot
RUN cd /opt/certbot
RUN wget https://dl.eff.org/certbot-auto
RUN chmod a+x ./certbot-auto
#RUN ./certbot-auto

# if you want Mailman
# --- 8 Install Mailman
#RUN echo 'mailman mailman/default_server_language en' | debconf-set-selections
#RUN apt-get -y install mailman
#ADD ./etc/aliases /etc/aliases
#RUN newaliases
#RUN service postfix restart
#RUN ln -s /etc/mailman/apache.conf /etc/apache2/conf-enabled/mailman.conf

# --- 9 Install PureFTPd And Quota (Not on Docker, not yet supported)
RUN apt-get -y install pure-ftpd-common pure-ftpd-mysql quota quotatool
RUN sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/g'  /etc/default/pure-ftpd-common
RUN sed -i 's/STANDALONE_OR_INETD=inetd/STANDALONE_OR_INETD=standalone/g'  /etc/default/pure-ftpd-common
RUN sed -i 's/UPLOADSCRIPT=/UPLOADSCRIPT=\/etc\/pure-ftpd\/clamav_check.sh/g'  /etc/default/pure-ftpd-common
ADD ./etc/pure-ftpd/clamav_check.sh /etc/pure-ftpd/clamav_check.sh
RUN echo 2 > /etc/pure-ftpd/conf/TLS
RUN echo 1 > /etc/pure-ftpd/conf/CallUploadScript
RUN mkdir -p /etc/ssl/private/
RUN openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=DE/ST=Karlsruhe/L=Baden-Wuerttemberg/O=IT/CN=$HOSTNAME" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
RUN chmod 600 /etc/ssl/private/pure-ftpd.pem

# --- 10 Install BIND DNS Server
RUN apt-get -y install bind9 dnsutils

# --- 11 Install Vlogger, Webalizer, And AWStats
RUN apt-get -y install vlogger awstats geoip-database libclass-dbi-mysql-perl
ADD etc/cron.d/awstats /etc/cron.d/

# --- 12 Install Jailkit
RUN apt-get -y install build-essential autoconf automake libtool flex bison debhelper binutils
RUN cd /tmp && wget http://olivier.sessink.nl/jailkit/jailkit-2.19.tar.gz && tar xvfz jailkit-2.19.tar.gz && cd jailkit-2.19 && ./debian/rules binary
RUN cd /tmp && dpkg -i jailkit_2.19-1_*.deb && rm -rf jailkit-2.19*

# --- 13 Install fail2ban
RUN apt-get -y install fail2ban
ADD ./etc/fail2ban/jail.local /etc/fail2ban/jail.local
ADD ./etc/fail2ban/filter.d/pureftpd.conf /etc/fail2ban/filter.d/pureftpd.conf
ADD ./etc/fail2ban/filter.d/dovecot-pop3imap.conf /etc/fail2ban/filter.d/dovecot-pop3imap.conf
RUN echo "ignoreregex =" >> /etc/fail2ban/filter.d/postfix-sasl.conf
RUN service fail2ban restart

# --- 14 Install RoundCube
RUN mkdir /opt/roundcube && cd /opt/roundcube && wget https://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.1.3/roundcubemail-1.1.3-complete.tar.gz && tar xfz roundcubemail-1.1.3-complete.tar.gz && mv roundcubemail-1.1.3/* . && mv roundcubemail-1.1.3/.htaccess . && rmdir roundcubemail-1.1.3 && rm roundcubemail-1.1.3-complete.tar.gz && chown -R www-data:www-data /opt/roundcube
RUN service mysql restart && mysql -h localhost -uroot -ppass -e "CREATE DATABASE roundcubemail; GRANT ALL PRIVILEGES ON roundcubemail.* TO roundcube@localhost IDENTIFIED BY 'secretpassword';flush privileges;"
RUN service mysql restart && mysql -h localhost -uroot -ppass roundcubemail < /opt/roundcube/SQL/mysql.initial.sql
RUN cd /opt/roundcube/config && cp -pf config.inc.php.sample config.inc.php
RUN sed -i "s/\$config[\'db_dsnw\'] = \'mysql:\/\/roundcube:pass@localhost\/roundcubemail';/\$config[\'db_dsnw\'] = \'mysql:\/\/roundcube:secretpassword@localhost\/roundcubemail\';/g" /opt/roundcube/config/config.inc.php
ADD ./etc/apache2/roundcube.conf /etc/apache2/conf-enabled/roundcube.conf
RUN service apache2 restart
RUN service mysql restart

# --- 15 Install ISPConfig 3
# Stable release
#RUN cd /tmp && wget -O ISPConfig-3.tar.gz wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz && tar xfz ISPConfig-3.tar.gz
# Beta release
RUN cd /tmp &&  wget -O ISPConfig-3.1-beta.tar.gz  https://git.ispconfig.org/ispconfig/ispconfig3/repository/archive.tar.gz?ref=stable-3.1 && tar xzf ISPConfig-3.1-beta.tar.gz && mv ispconfig3-stable-3.1-* ispconfig3-stable-3.1
RUN service mysql restart

ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf

RUN echo "export TERM=xterm" >> /root/.bashrc

EXPOSE 20 21 22 53/udp 53/tcp 80 443 953 8080 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009 3306

# ISPCONFIG Initialization and Startup Script
ADD ./start.sh /start.sh
ADD ./supervisord.conf /etc/supervisor/supervisord.conf
ADD ./etc/cron.daily/sql_backup.sh /etc/cron.daily/sql_backup.sh
ADD ./autoinstall.ini /tmp/ispconfig3-stable-3.1/install/autoinstall.ini
RUN chmod 755 /start.sh
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor
RUN mv /bin/systemctl /bin/systemctloriginal
ADD ./bin/systemctl /bin/systemctl

RUN sed -i "s/^hostname=server1.example.com$/hostname=$HOSTNAME/g" /tmp/ispconfig3-stable-3.1/install/autoinstall.ini
RUN service mysql restart && php -q /tmp/ispconfig3-stable-3.1/install/install.php --autoinstall=/tmp/ispconfig3-stable-3.1/install/autoinstall.ini
RUN service mysql restart
RUN mkdir -p /var/backup/sql

VOLUME ["/var/www/","/var/mail/","/var/backup/","/var/lib/mysql","/etc/","/usr/local/ispconfig","/var/log/"]

CMD ["/bin/bash", "/start.sh"]
