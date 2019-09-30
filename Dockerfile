FROM centos:7

# Assign Environment Variables
ENV DB_HOST=db
ENV DB_DATABASE=test_db
ENV DB_USERNAME=lara
ENV DB_PASSWORD=password

# Add laravel user, lara
RUN useradd lara
RUN usermod -aG wheel lara
RUN echo "password" | passwd --stdin lara

# Install Apache
RUN yum -y update
RUN yum -y install httpd httpd-tools


# Install EPEL Repo
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# Install PHP
RUN yum -y install php72w php72w-bcmath php72w-cli php72w-common php72w-gd php72w-intl php72w-ldap php72w-mbstring \
    php72w-mysql php72w-pear php72w-soap php72w-xml php72w-xmlrpc

# Update Apache Configuration
RUN sed -E -i -e '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
RUN sed -E -i -e 's/DirectoryIndex (.*)$/DirectoryIndex index.php \1/g' /etc/httpd/conf/httpd.conf

# Install Composer
RUN yum -y install php-cli php-zip wget unzip --skip-broken
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install laravel
RUN composer create-project laravel/laravel /var/www/html/laravel

# Edit httpd file
RUN sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html/laravel/public"|g' /etc/httpd/conf/httpd.conf
RUN chown -R apache:apache /var/www/html/laravel
RUN chmod -R 755 /var/www/html/laravel/storage


# Edit Laravel file
RUN sed -i 's|DB_HOST=127.0.0.1|DB_HOST=db|g' /var/www/html/laravel/.env
RUN sed -i 's|DB_DATABASE=laravel|DB_DATABASE=test_db|g' /var/www/html/laravel/.env
RUN sed -i 's|DB_USERNAME=root|DB_USERNAME=lara|g' /var/www/html/laravel/.env
RUN sed -i 's|DB_PASSWORD=|DB_PASSWORD=password|g' /var/www/html/laravel/.env


EXPOSE 80

# Start Apache
CMD ["/usr/sbin/httpd","-D","FOREGROUND"]
