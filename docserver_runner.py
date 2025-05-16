import sys
import subprocess

# sys.argv.append('9.0.0.108')
# sys.argv.append('docserver_custom')

# print(sys.argv)
def get_arg(position, default=None):
    try:
        return sys.argv[position]
    except IndexError:
        return default


if not get_arg(1):
    sys.exit('Не указана версия образа documentserver')

image_version = get_arg(1)
image_name = f"onlyoffice/4testing-documentserver-ee:{image_version}"
is_dev = image_version.startswith('99.99')
container_name = get_arg(2) if get_arg(2) else f"docserver{'_dev' if is_dev else ''}"

# запускаем контейнер с образом соответствующей версии
# --env JWT_ENABLED=true --env JWT_SECRET=jwtsecret --env JWT_HEADER=Authorization \
command = (
    f"docker run -itd -p 80:80 {'--restart unless-stopped ' if not is_dev else ''}"
    "--env ALLOW_PRIVATE_IP_ADDRESS=true --env JWT_ENABLED=false "
    "--volume ~/DocumentServer/logs:/var/log/onlyoffice "
    "--volume ~/DocumentServer/data:/var/www/onlyoffice/Data "
    "--volume ~/DocumentServer/lib:/var/lib/onlyoffice "
    "--volume ~/DocumentServer/db:/var/lib/postgresql "
    f"--name {container_name} {image_name}"
)
try:
    result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
except subprocess.CalledProcessError as e:
    sys.exit(f"Stderr: {e.stderr}")

if result.returncode == 0:
    # проверить состояние сервисов: docker exec docserver sudo supervisorctl
    # запускаем сервис example, т.к. по умолчанию он отключен
    subprocess.run(
        f"docker exec {container_name} "
        "sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf", 
        shell=True,
    )
    subprocess.run(
        f"docker exec {container_name} "
        "sed -i 's/WARN/ALL/g' /etc/onlyoffice/documentserver/log4js/production.json",
        shell=True,
    )
    subprocess.run(
        f"docker exec {container_name} "
        "sed -i 's,access_log off,access_log /var/log/onlyoffice/documentserver/nginx.access.log,' "
        "/etc/onlyoffice/documentserver/nginx/includes/ds-common.conf",
        shell=True,
    )
    print(f"Контейнер {container_name} успешно запущен")
else:
    print(f"Не удалось запустить контейнер: {result.returncode}, {result.stderr}")
