FROM hadoop-base:3.2.1

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:10000/ || exit 1


# docker arguemnts로 HIVE_VERSION이 없으면 대치
ARG HIVE_VERSION
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}

ENV HIVE_HOME /opt/hive
ENV HIVE_CONF_DIR ${HIVE_HOME}/conf
ENV PATH $HIVE_HOME/bin:$PATH
ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION

WORKDIR /opt

# download hive, mariadb connetor
RUN yum install -y wget procps
# RUN wget --no-check-certificate https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz
RUN wget --no-check-certificate https://downloads.apache.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz
RUN tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz
RUN	mv apache-hive-$HIVE_VERSION-bin hive
RUN rm apache-hive-$HIVE_VERSION-bin.tar.gz

RUN wget --no-check-certificate https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.17/mysql-connector-java-8.0.17.jar -O $HIVE_HOME/lib/mysql-connector-java-8.0.17.jar
# RUN wget --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.2.2.jar -O $HIVE_HOME/lib/postgresql-jdbc.jar

# https://issues.apache.org/jira/browse/HIVE-22915
RUN ls -l $HIVE_HOME/lib/
RUN rm $HIVE_HOME/lib/guava*
RUN cp $HADOOP_HOME/share/hadoop/hdfs/lib/guava* $HIVE_HOME/lib/

ADD conf/hive-site.xml $HIVE_HOME/conf
ADD conf/beeline-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-env.sh $HIVE_HOME/conf
ADD conf/hive-exec-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-log4j2.properties $HIVE_HOME/conf
ADD conf/ivysettings.xml $HIVE_HOME/conf
ADD conf/llap-daemon-log4j2.properties $HIVE_HOME/conf

ADD run.sh run.sh
RUN chmod a+x run.sh
RUN sed -i 's/\r$//' run.sh

# HIVE_SERVER2_THRIFT_PORT, hive web UI
EXPOSE 10000 10002

# # hadoop-base꺼를 수행한 뒤에 아래 라인을 수행하게끔 함
ENTRYPOINT ["/entrypoint.sh"]

CMD ./run.sh
