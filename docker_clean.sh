docker rm %container%
docker volume prune
docker rmi %image%
docker system df
