#!/bin/bash

# if [[ "${LOCAL}" -eq "1" ]]; then
#   export ENCRYPT_KEY=$(cat key.txt)
# fi

if [[ "${BATCH}" -eq "1" ]]; then
  if [[ "${LOCAL}" -eq "1" ]]; then
    echo "this environment is local"
    echo "* * * * * cd /var/www/html && php artisan schedule:run" >> /etc/crontab
    crontab /etc/crontab
  else
    echo "* * * * * cd /var/www/html && php artisan schedule:run" >> /var/spool/cron/www
    crontab /var/spool/cron/www
  fi
  crond -n
elif [[ "${QUEUE}" -eq "1" ]]; then
  php artisan queue:work sqs
else
  if [[ "${LOCAL}" -eq "1" ]]; then
    mv /etc/php-fpm.d/www.conf.local /etc/php-fpm.d/www.conf
    /usr/sbin/php-fpm -F --allow-to-run-as-root
  else
    /usr/sbin/php-fpm -F
  fi
fi
