# frozen_string_literal: true

# ARGV[0] = '99.99.1.16'
abort 'Не указана версия образа documentserver' if ARGV[0] == nil

image_version = ARGV[0]
image_name = "onlyoffice/4testing-documentserver-ee:#{image_version}"

is_dev = image_version.start_with?('99.99')
container_name = "docserver#{'_dev' if is_dev}"

# запускаем контейнер с образом соответствующей версии
command = "docker run -i -t -d -p 80:80 #{'--restart unless-stopped ' if !is_dev}\
--env JWT_ENABLED=false --env ALLOW_PRIVATE_IP_ADDRESS=true \
--volume ~/DocumentServer/logs:/var/log/onlyoffice  \
--volume ~/DocumentServer/data:/var/www/onlyoffice/Data  \
--volume ~/DocumentServer/lib:/var/lib/onlyoffice \
--volume ~/DocumentServer/db:/var/lib/postgresql \
--name #{container_name} #{image_name}"
result = system(command)

if result
  # проверить состояние сервисов: docker exec docserver sudo supervisorctl
  # запускаем сервис example, т.к. по умолчанию он отключен
  system "docker exec #{container_name} \
sudo sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf"
else
  abort "Не удалось запустить контейнер для #{image_name}"
end
