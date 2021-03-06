#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
VERSION=1.15.2
DISTDIR="/root/work/pontus-git/pontus-dist/opt/pontus/pontus-nginx";
TARFILE=$DIR/pontus-nginx-${VERSION}.tar.gz

CURDIR=`pwd`
cd $DIR

echo DIR is $DIR
echo TARFILE is $TARFILE

if [[ ! -f $TARFILE ]]; then

yum -y install attr bind-utils docbook-style-xsl gcc gdb krb5-workstation        libsemanage-python libxslt perl perl-ExtUtils-MakeMaker        perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python        python-crypto gnutls-devel libattr-devel keyutils-libs-devel        libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel        pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel

./auto/configure  --prefix=/opt/pontus/pontus-nginx/nginx-${VERSION}
make -j 4
make install


tar cpzvf ${TARFILE} /opt/pontus/pontus-nginx

fi

if [[ ! -d $DISTDIR ]]; then
  mkdir -p $DISTDIR
fi

cd $DISTDIR
rm -rf *
cd $DISTDIR/../../../
tar xvfz $TARFILE
cd $DISTDIR
ln -s nginx-$VERSION current
cd current

cat <<'EOF' >> config-nginx.sh
#!/bin/bash


cat << 'EOF2' >> /opt/pontus/pontus-nginx/nginx-${VERSION}/config/nginx.conf
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;




events {
    worker_connections  1024;
}


https {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen 8443;
        root /wwwroot;
        ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers                 ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers   on;
        ssl_ecdh_curve              secp384r1;


        location / {
            root /wwwroot;
            index index.html;

            try_files $uri $uri/ /wwwroot/index.html;
        }


    }
}

EOF2

cat << 'EOF2' >> /etc/systemd/system/pontus-nginx.service
[Unit]
Description=Pontus Nginx
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/opt/pontus/pontus-nginx/current/sbin/nginx -D
PIDFile=/opt/pontus/pontus-nginx/current/nginx.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target

EOF2

chown -R pontus: /opt/pontus/pontus-nginx

EOF

chmod 755 config-nginx.sh
cd $CURDIR

echo DISTDIR is $DISTDIR
