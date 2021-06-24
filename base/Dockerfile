# change from debian:9 to centos:7

FROM centos:7


# update
RUN yum -y update

# 기타
RUN yum install -y gcc
RUN yum groupinstall -y "Development Tools"
RUN yum install -y wget \
    && yum install -y zlib-devel

# JAVA
RUN yum list java*jdk-devel
RUN yum install -y java-1.8.0-openjdk
RUN yum install -y java-1.8.0-openjdk-devel
RUN readlink -f /usr/bin/java
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el7_9.x86_64/jre
# RUN echo "JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.282.b08-1.el7_9.x86_64/jre/bin/java" >> /etc/profile
# RUN echo "PATH=$PATH:$JAVA_HOME/bin" >> /etc/profile
# RUN echo "CLASSPATH=$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar" >> /etc/profile
# RUN source /etc/profile
ENV PATH $JAVA_HOME/bin/:$PATH
ENV CLASSPATH $JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
RUN javac -version

# python 설치
RUN yum install -y python-virtualenv
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tgz
RUN tar -zxvf Python-3.6.8.tgz 
WORKDIR /Python-3.6.8
RUN ./configure && make && make install
# RUN ./configure --enable-loadable-sqlite-extensions && make && make install
RUN pip3 install --upgrade pip


# 설치 파일들
RUN yum -y install net-tools curl netcat gnupg libsnappy-dev

RUN curl --insecure -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS
RUN gpg --import KEYS

RUN yum install -y net-tools \
      perl \
      curl \
      netcat \
      gnupg \
      libsnappy-dev \
      nc
      

# --insecure 관련 부분은 생략해도 됨
RUN curl --insecure -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS
# RUN curl -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS

RUN gpg --import KEYS

ENV HADOOP_VERSION 3.1.2
# ENV HADOOP_URL https://downloads.apache.org/hadoop/common/current/hadoop-$HADOOP_VERSION.tar.gz
ENV HADOOP_URL https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-${HADOOP_VERSION}.tar.gz

RUN curl -fSL --insecure "$HADOOP_URL" -o /tmp/hadoop.tar.gz \
    && curl -fSL --insecure "$HADOOP_URL.asc" -o /tmp/hadoop.tar.gz.asc \
    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xvf /tmp/hadoop.tar.gz -C /opt/ \
    && rm -rf /tmp/hadoop.tar.gz*

RUN ln -s /opt/hadoop-${HADOOP_VERSION} /opt/hadoop
RUN ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop

RUN mkdir /opt/hadoop-$HADOOP_VERSION/logs

RUN mkdir /hadoop-data

ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR /etc/hadoop
ENV MULTIHOMED_NETWORK 1
ENV USER root
ENV PATH $HADOOP_HOME/bin/:$PATH
ENV HADOOP_CLASSPATH $JAVA_HOME/lib/tools.jar

COPY entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

# windows에서 작업할 경우 아래와 같은 처리 해야 함
RUN sed -i 's/\r$//' /entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
