#
#                    ##        .            
#              ## ## ##       ==            
#           ## ## ## ##      ===            
#       /""""""""""""""""\___/ ===        
#  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~   
#       \______ o          __/            
#         \    \        __/             
#          \____\______/                
# 
#          |          |
#       __ |  __   __ | _  __   _
#      /  \| /  \ /   |/  / _\ | 
#      \__/| \__/ \__ |\_ \__  |
#
# Dockerfile for ISPConfig with MariaDB database
#
# https://www.howtoforge.com/tutorial/perfect-server-debian-8-4-jessie-apache-bind-dovecot-ispconfig-3-1
#

FROM debian:jessie

MAINTAINER Zoltan Lanyi <zoltan.lanyi@gmail.com> version: 0.1

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# --- 1 Preliminary
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install rsyslog rsyslog-relp logrotate supervisor
RUN touch /var/log/cron.log
# Create the log file to be able to run tail
RUN touch /var/log/auth.log

# --- 2 Install the SSH server
RUN apt-get -y install ssh openssh-server rsync

# --- 3 Install a shell text editor
RUN apt-get -y install nano vim-nox

# --- 5 Update Your Debian Installation
ADD ./etc/apt/sources.list /etc/apt/sources.list
RUN apt-get -y update && apt-get -y upgrade

# --- 6 Change The Default Shell
RUN echo "dash  dash/sh boolean no" | debconf-set-selections
RUN dpkg-reconfigure dash

# --- 7 Synchronize the System Clock
RUN apt-get -y install ntp ntpdate

# --- 8 Install Postfix, Dovecot, MySQL, phpMyAdmin, rkhunter, binutils
RUN echo 'mysql-server mysql-server/root_password password pass' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password pass' | debconf-set-selections
RUN echo 'mariadb-server mariadb-server/root_password password pass' | debconf-set-selections
RUN echo 'mariadb-server mariadb-server/root_password_again password pass' | debconf-set-selections
RUN apt-get -y install postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
RUN service postfix restart
RUN service mysql restart

# --- 9 Install Amavisd-new, SpamAssassin And Clamav
RUN apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf
RUN service spamassassin stop
RUN systemctl disable spamassassin

# --- 10 Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password pass' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
RUN service mysql restart && apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-itk apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached libapache2-mod-passenger libapache2-mod-evasive libapache2-mod-security2
RUN a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi

# --- 11 Free SSL
RUN mkdir /opt/certbot
RUN cd /opt/certbot
RUN wget https://dl.eff.org/certbot-auto
RUN chmod a+x ./certbot-auto
#RUN ./certbot-auto

# --- 12 XCache
RUN apt-get -y install php5-xcache

# if you want Mailman
# --- 13 Install Mailman
#RUN echo 'mailman mailman/default_server_language en' | debconf-set-selections
#RUN apt-get -y install mailman
#ADD ./etc/aliases /etc/aliases
#RUN newaliases
#RUN service postfix restart
#RUN ln -s /etc/mailman/apache.conf /etc/apache2/conf-enabled/mailman.conf

# --- 14 Install PureFTPd And Quota
RUN apt-get -y install pure-ftpd-common pure-ftpd-mysql
RUN sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/g'  /etc/default/pure-ftpd-common
RUN sed -i 's/STANDALONE_OR_INETD=inetd/STANDALONE_OR_INETD=standalone/g'  /etc/default/pure-ftpd-common
RUN sed -i 's/UPLOADSCRIPT=/UPLOADSCRIPT=\/etc\/pure-ftpd\/clamav_check.sh/g'  /etc/default/pure-ftpd-common
ADD ./etc/pure-ftpd/clamav_check.sh /etc/pure-ftpd/clamav_check.sh
RUN echo 1 > /etc/pure-ftpd/conf/TLS
RUN mkdir -p /etc/ssl/private/
# RUN openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
# RUN chmod 600 /etc/ssl/private/pure-ftpd.pem
# RUN service pure-ftpd-mysql restart

# --- 15 Install BIND DNS Server
RUN apt-get -y install bind9 dnsutils

# --- 16 Install Vlogger, Webalizer, And AWStats
RUN apt-get -y install vlogger awstats geoip-database libclass-dbi-mysql-perl
ADD etc/cron.d/awstats /etc/cron.d/

# --- 17 Install Jailkit
RUN apt-get -y install build-essential autoconf automake libtool flex bison debhelper binutils
RUN cd /tmp && wget http://olivier.sessink.nl/jailkit/jailkit-2.19.tar.gz && tar xvfz jailkit-2.19.tar.gz && cd jailkit-2.19 && ./debian/rules binary
RUN cd /tmp && dpkg -i jailkit_2.19-1_*.deb && rm -rf jailkit-2.19*

# --- 18 Install fail2ban
RUN apt-get -y install fail2ban
ADD ./etc/fail2ban/jail.local /etc/fail2ban/jail.local
ADD ./etc/fail2ban/filter.d/pureftpd.conf /etc/fail2ban/filter.d/pureftpd.conf
ADD ./etc/fail2ban/filter.d/dovecot-pop3imap.conf /etc/fail2ban/filter.d/dovecot-pop3imap.conf
RUN echo "ignoreregex =" >> /etc/fail2ban/filter.d/postfix-sasl.conf
RUN service fail2ban restart

# --- 19 Install RoundCube
RUN mkdir /opt/roundcube && cd /opt/roundcube
RUN wget https://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.1.3/roundcubemail-1.1.3-complete.tar.gz && tar xfz roundcubemail-1.1.3-complete.tar.gz
RUN mv roundcubemail-1.1.3/* . && mv roundcubemail-1.1.3/.htaccess . && rm -rf roundcubemail-1.1.* && chown -R www-data:www-data /opt/roundcube
RUN mysql --defaults-file=/etc/mysql/debian.cnf -e "CREATE DATABASE roundcubemail; GRANT ALL PRIVILEGES ON roundcubemail.* TO roundcube@localhost IDENTIFIED BY 'secretpassword';flush privileges;"
RUN mysql --defaults-file=/etc/mysql/debian.cnf roundcubemail < /opt/roundcube/SQL/mysql.initial.sql
RUN cd /opt/roundcube/config && cp -pf config.inc.php.sample config.inc.php
RUN sed -i 's/$config['db_dsnw'] = 'mysql://roundcube:pass@localhost\/roundcubemail';/$config['db_dsnw'] = 'mysql://roundcube:secretpassword@localhost\/roundcubemail';/g' /opt/roundcube/config
ADD ./etc/apache2/conf-enabled/roundcube.conf /etc/apache2/conf-enabled/roundcube.conf
RUN service apache2 restart

# --- 20 Install ISPConfig 3
# RUN cd /tmp && cd . && wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
RUN cd /tmp && cd . && wget -O ISPConfig-3.tar.gz http://www.ispconfig.org/downloads/ISPConfig-3.0.5.4p8.tar.gz
RUN cd /tmp && tar xfz ISPConfig-3.tar.gz
RUN service mysql restart
# RUN ["/bin/bash", "-c", "cat /tmp/install_ispconfig.txt | php -q /tmp/ispconfig3_install/install/install.php"]
# RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
# RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
# RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini

# ADD ./etc/mysql/my.cnf /etc/mysql/my.cnf
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf

RUN echo "export TERM=xterm" >> /root/.bashrc

EXPOSE 20 21 22 53/udp 53/tcp 80 443 953 8080 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009 3306

# ISPCONFIG Initialization and Startup Script
ADD ./start.sh /start.sh
ADD ./supervisord.conf /etc/supervisor/supervisord.conf
ADD ./etc/cron.daily/sql_backup.sh /etc/cron.daily/sql_backup.sh
ADD ./autoinstall.ini /tmp/ispconfig3_install/install/autoinstall.ini
RUN chmod 755 /start.sh
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor
RUN mv /bin/systemctl /bin/systemctloriginal
ADD ./bin/systemctl /bin/systemctl

RUN sed -i "s/^hostname=server1.example.com$/hostname=$HOSTNAME/g" /tmp/ispconfig3_install/install/autoinstall.ini
# RUN mysqladmin -u root password pass
RUN service mysql restart && php -q /tmp/ispconfig3_install/install/install.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
ADD ./ISPConfig_Clean-3.0.5 /tmp/ISPConfig_Clean-3.0.5
RUN cp -r /tmp/ISPConfig_Clean-3.0.5/interface /usr/local/ispconfig/
RUN service mysql restart && mysql -ppass < /tmp/ISPConfig_Clean-3.0.5/sql/ispc-clean.sql
# Directory for dump SQL backup
RUN mkdir -p /var/backup/sql

VOLUME ["/var/www/","/var/mail/","/var/backup/","/var/lib/mysql","/etc/","/usr/local/ispconfig","/var/log/"]

CMD ["/bin/bash", "/start.sh"]
