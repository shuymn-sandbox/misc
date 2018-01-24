echo '[ START PROVISIONING ]'

echo '[1.1] Set timezone to Asia/Tokyo'
timedatectl set-timezone Asia/Tokyo

echo '[1.2] Stop selinux'
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo '[1.3] Update all'
echo 'Updating ...'
yum update -y 1>/dev/null

echo '[1.4] Install git, vim and unzip'
echo 'Installing ...'
yum install git vim unzip -y 1>/dev/null

# デフォルトではリポジトリを無効にする
# rpm と yum の違い : http://blog.inouetakuya.info/entry/20111006/1317900802
echo '[1.5] Add EPEL and Remi repository'
echo 'Adding ...'
yum install epel-release -y 1>/dev/null
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo
yum install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm -y 1>/dev/null 

echo '[2.1] Install nginx from EPEL repository'
echo 'Installing ...'
yum --enablerepo=epel install nginx -y 1>/dev/null

echo '[2.2] Change directory owner for nginx'
mkdir -p /var/www
chown nginx:nginx /var/www
chmod o+w -R /var/www

echo '[2.3] Create phpinfo.php'
echo '<?php phpinfo();' >> /var/www/index.php && chown nginx:nginx /var/www/index.php

echo '[2.4] Add nginx config (local.dev.conf)'
cat << EOT > /etc/nginx/conf.d/local.dev.conf
server {
  listen 80;
  server_name local.dev;
  charset utf-8;

  root /var/www;
  index index.php index.html index.htm;

  location / {
    index index.html index.htm index.php;
    try_files \$uri \$uri/ /index.php?\$query_string;
  }

  location ~ \.(php|html)$ {
    fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
  }
}
EOT

echo '[2.5] Fix folder sync bug between virtualbox and nginx'
sed -i.bak 's/sendfile\s\+on/sendfile off/g' /etc/nginx/nginx.conf

echo '[2.6] Start nginx and set autostart'
systemctl enable nginx 1>/dev/null 2>/dev/null
systemctl start nginx
systemctl status nginx | grep --color=never Active

echo '[3.1] Install php7.1 and php-fpm and some extensions'
echo 'Installing ...'
# php7.1とphp-fpmなどのextensionをインストール
yum install --enablerepo=epel,remi-php71 php php-mbstring php-pear php-fpm php-mcrypt php-gd php-mysql -y 1>/dev/null

# php.iniの基本的な設定
echo '[3.2] Change php.ini'
sed -i.bak -e 's/;date.timezone =/date.timezone = \"Asia\/Tokyo\"/g' \
  -e 's/;mbstring.lang/mbstring.lang/g' \
  -e 's/;mbstring.internal_encoding =/mbstring.internal_encoding = UTF-8/g' \
  -e 's/;mbstring.http_input = /mbstring.http_input = pass/g' \
  -e 's/;mbstring.http_output =/mbstring.http_output = pass/g' \
  -e 's/;mbstring.encoding_translation/mbstring.encoding_translation/g' \
  -e 's/;mbstring.detect_order/mbstring.detect_order/g' \
  -e 's/expose_php = On/expose_php = Off/g' \
  -e 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/g' \
  -e 's/display_errors = Off/display_errors = On/g' \
  -e 's/display_startup_errors = Off/display_startup_errors = On/g' /etc/php.ini

# php-fpm の user と group を変更
echo '[3.3] Change php-fpm config'
sed -i.bak -e 's/user = apache/user = nginx/g' \
  -e 's/group = apache/group = nginx/g' \
  -e 's/;listen.owner = nobody/listen.owner = nginx/g' \
  -e 's/;listen.group = nobody/listen.group = nginx/g' \
  -e 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf

echo '[2.5] Start php-fpm and set autostart'
systemctl enable php-fpm 1>/dev/null 2>/dev/null
systemctl start php-fpm
systemctl status php-fpm | grep --color=never Active

# mysql5.7 のリポジトリ追加とインストール
echo '[3.1] Add mysql5.7 repository'
echo 'Adding ...'
yum localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm -y 1>/dev/null

echo '[3.2] Install mysql5.7 community server'
echo 'Installing ...'
yum install mysql-community-server -y 1>/dev/null

# vagrant ではパスワードなしでmysqlのrootユーザのログインを許可する
echo '[3.3] Change mysql config'
echo skip-grant-tables >> /etc/my.cnf

# mysql の起動と自動起動設定
echo '[3.4] Start mysql and set autostart'
systemctl enable mysqld 1>/dev/null 2>/dev/null
systemctl start mysqld
systemctl status mysqld | grep --color=never Active

echo '[4.1] Install composer'
echo 'Installing ...'
# setup.phpのダウンロード
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" 1>/dev/null
php composer-setup.php 1>/dev/null
# setup.phpの削除
php -r "unlink('composer-setup.php');" 1>/dev/null
mv composer.phar /usr/local/bin/composer

echo '[ FINISH PROVISIONING ]'
