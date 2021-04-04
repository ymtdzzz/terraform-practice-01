FROM centos:7

ENV WORKDIR=/var/www/html
WORKDIR $WORKDIR

RUN yum update -y
RUN yum -y remove httpd httpd.x86_64 httpd-tools.x86_64

# install leatest apache2.4.*
RUN yum install -y epel-release wget && \
    yum -y install https://repo.ius.io/ius-release-el7.rpm && \
    sed -i -e "s/enabled *= *1/enabled=0/g" /etc/yum.repos.d/ius.repo && \
    sed -i -e "s/enabled *= *1/enabled=0/g" /etc/yum.repos.d/epel.repo
RUN wget http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/b/brotli-1.0.7-5.el7.x86_64.rpm && \
    rpm -Uvh brotli-1.0.7-5.el7.x86_64.rpm
RUN yum --enablerepo=epel -y install nghttp2 && \
    yum -y install epel-release && \
    yum -y install mailcap system-logos && \
    yum -y install openssl && \
    yum -y --disablerepo=base,extras,updates --enablerepo=ius install httpd mod_ssl && \
    yum clean all
RUN sed -i -e "s|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|" /etc/httpd/conf.modules.d/00-mpm.conf && \
    sed -i -e "s|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|" /etc/httpd/conf.modules.d/00-mpm.conf

ENV PHP_HOST=127.0.0.1

COPY . .
COPY ./docker/apache/docker.conf /etc/httpd/conf.d/docker.conf.template

# dockre can not use systemd without permission, apahce is started with httpd
CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/httpd/conf.d/docker.conf.template > /etc/httpd/conf.d/docker.conf && /usr/sbin/httpd -DFOREGROUND'