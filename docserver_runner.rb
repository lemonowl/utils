# frozen_string_literal: true

# ARGV[0] = '99.99.99.3953'
# ARGV[1] = 'docserver_test'
abort 'Не указана версия образа documentserver' if ARGV[0] == nil

image_version = ARGV[0]
image_name = "onlyoffice/4testing-documentserver-ee:#{image_version}"

is_dev = image_version.start_with?('99.99')
container_name = !ARGV[1].nil? ? ARGV[1] : "docserver#{'_dev' if is_dev}"

# запускаем контейнер с образом соответствующей версии
# --env JWT_ENABLED=true --env JWT_SECRET=jwtsecret --env JWT_HEADER=Authorization \
command = "docker run -i -t -d -p 80:80 #{'--restart unless-stopped' unless is_dev} \
--env ALLOW_PRIVATE_IP_ADDRESS=true --env JWT_ENABLED=false \
--volume ~/DocumentServer/logs:/var/log/onlyoffice \
--volume ~/DocumentServer/data:/var/www/onlyoffice/Data \
--volume ~/DocumentServer/lib:/var/lib/onlyoffice \
--volume ~/DocumentServer/db:/var/lib/postgresql \
--name #{container_name} #{image_name}"
result = system(command)

if result
  # проверить состояние сервисов: docker exec docserver sudo supervisorctl
  # запускаем сервис example, т.к. по умолчанию он отключен
  system "docker exec -it #{container_name} sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf"
  system "docker exec -it #{container_name} sed -i 's/WARN/ALL/g' /etc/onlyoffice/documentserver/log4js/production.json"
  system "docker exec -it #{container_name} sed -i 's,access_log off,access_log /var/log/onlyoffice/documentserver/nginx.access.log,' /etc/onlyoffice/documentserver/nginx/includes/ds-common.conf"
else
  abort "Не удалось запустить контейнер для #{image_name}"
end
