#! /bin/bash
variable1=$0
variable2=${1:-$variable1}
# variable3=$2

echo $variable1, $variable2

if [[ $variable2 = *"build"* ]]; then
  echo "input argument [stop | start] [nifi=#number]"
elif [[ $variable2 = *"stop"* ]]; then
  echo "stop"
  docker-compose -f docker-compose-was.yml down
  docker-compose -f docker-compose-hadoop.yml down
else
  echo "start...."

  
  # build hadoop images
  VERSION=3.1.2
  HIVE_VERSION=3.1.2
  echo -e "\ndocker build -t hadoop-base:$VERSION base/."
  docker build -t hadoop-base:$VERSION base/.
  echo -e "\ndocker build -t hadoop-namenode:$VERSION namenode/."
  docker build -t hadoop-namenode:$VERSION namenode/.
  echo -e "\ndocker build -t hadoop-datanode:$VERSION datanode/."
  docker build -t hadoop-datanode:$VERSION datanode/.
  echo -e "\ndocker build -t hadoop-resourcemanager:$VERSION resourcemanager/."
  docker build -t hadoop-resourcemanager:$VERSION resourcemanager/.
  echo -e "\ndocker build -t hadoop-nodemanager:$VERSION nodemanager/."
  docker build -t hadoop-nodemanager:$VERSION nodemanager/.
  echo -e "\ndocker build -t hadoop-historyserver:$VERSION historyserver/."
  docker build -t hadoop-historyserver:$VERSION historyserver/.
  # echo -e "\n docker build -t hadoop-hive:$HIVE_VERSION hive/."
  # docker build -t hadoop-hive:$HIVE_VERSION hive/.

  
  # echo "docker-compose up --scale nifi=3 -d --build"
  # docker-compose up --scale nifi=3 -d --build
  echo "docker-compose up -d --build"
  docker-compose -f docker-compose-was.yml up -d --build
  docker-compose -f docker-compose-hadoop.yml up -d
fi
