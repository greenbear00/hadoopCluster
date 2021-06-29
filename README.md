
# 변경사항
- 참조: https://gitter.im/big-data-europe/Lobby
- debian:9 to centos:7 (2021.03.30)
- datanode 1개로 구성 (각각 주석 해제하면 3개로 구성됨)
    + local test를 위해 dfs.replication=1로 설정
- hive metastore db를 mysql로 변경


## nifi
- flask의 DB인 postgres를 nifi를 통하여 hive와 연동 (CRUD)
- elastic의 로그(nginx, flask)를 hive와 연동
- nifi 클러스터 적용 및 dashboard 확인
    ```
        # nifi를 클러스터로 띄움
        > 현재는 docker-compose에 nifi node를 2개로 cluster로 구성함
        > 실제 --scale로 할 경우 volume 이슈가 발생했음. (docker-compose --scale nifi=3 -d --build)
            > --scale로 할경우, docker-compose ps 를 통해서 simpleweb_nifi_#별로, 내부 8080포트로 연동되는 외부 port로 접근해야 함 (예: http://localhost:51151/nifi)

                            Name                    Command                   State                                                                        Ports
            -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            es01               /tini -- /usr/local/bin/do ...   Up (healthy)     0.0.0.0:9200->9200/tcp,:::9200->9200/tcp, 9300/tcp
            es02               /tini -- /usr/local/bin/do ...   Up               9200/tcp, 0.0.0.0:9201->9201/tcp,:::9201->9201/tcp, 9300/tcp
            es03               /tini -- /usr/local/bin/do ...   Up               9200/tcp, 0.0.0.0:9202->9202/tcp,:::9202->9202/tcp, 9300/tcp
            flask              uwsgi uwsgi.ini                  Up               0.0.0.0:5000->5000/tcp,:::5000->5000/tcp
            kib01              /usr/local/bin/dumb-init - ...   Up (unhealthy)   0.0.0.0:5601->5601/tcp,:::5601->5601/tcp
            logstash           /usr/local/bin/docker-entr ...   Up (unhealthy)   0.0.0.0:5001->5001/tcp,:::5001->5001/tcp, 0.0.0.0:5001->5001/udp,:::5001->5001/udp, 5044/tcp, 0.0.0.0:9600->9600/tcp,:::9600->9600/tcp
            nginx              /docker-entrypoint.sh ngin ...   Up               80/tcp, 0.0.0.0:8081->8081/tcp,:::8081->8081/tcp
            postgres           docker-entrypoint.sh postgres    Up               0.0.0.0:5432->5432/tcp,:::5432->5432/tcp
            simpleweb_nifi_1   ../scripts/start.sh              Up               10000/tcp, 8000/tcp, 0.0.0.0:51157->8080/tcp, 8443/tcp
            simpleweb_nifi_2   ../scripts/start.sh              Up               10000/tcp, 8000/tcp, 0.0.0.0:51158->8080/tcp, 8443/tcp
            simpleweb_nifi_3   ../scripts/start.sh              Up               10000/tcp, 8000/tcp, 0.0.0.0:51156->8080/tcp, 8443/tcp
            zookeeper          /etc/confluent/docker/run        Up               0.0.0.0:2181->2181/tcp,:::2181->2181/tcp, 2888/tcp, 3888/tcp


    ```
- nifi postgres 관련
    - GenerateTableFetch
        - DBCPConnectionPool
            - database connection url: jdbc:postgresql://postgres:postgres@postgres:5432/simple
            - database driver class name: org.postgresql.Driver
            - database driver location(s): /opt/driver/postgresql-42.2.21.jar
- nifi-registry 연동
    - nifi Web UI에서 controller settings을 통해 nifi-registry(http://nifi-registry:18080)을 등록해야 함
    - nifi Web UI가 띄워지면, process group을 통해 import 시키면 nifi-registry에 저장된 nifi process group을 import 시킬 수 있음
    - nifi-registry UI: http://nifi-registry:18080
    - nifi-registry 연동으로 인한 nifi_1, nifi_2의 포트는 모두 8081, 8082로 변경 처리함
    - nifi-registry에 등록되어 있는 bucket이 있으면, 그걸 nifi 웹UI에서 process group을 생성한 후에 import를 하면 됨 
    - 참고로 sample template는 .nifi/template에 존재
- template import 방법
    - nifi 화면에서 왼쪽 Operate를 통해 [Upload template] 아이콘을 선택 -> 상단 [Template] 메뉴를 통해 upload한 template 중 필요한 template 로드
    
### nifi flow 예제
- .nifi/flow_backup/rdb_to_hive.xml 파일은 rdb(즉, postgres의 simple.users) 데이터를 가져와서 hdfs -> hive로 insert 함



## hadoop

2. 서비스 확인 방법
    + default ports used by hadoop services : https://kontext.tech/column/hadoop/265/default-ports-used-by-hadoop-services-hdfs-mapreduce-yarn
3. namenode test
    ```
    docker exec [container_name] [command]
    
    $ docker exec namenode hadoop dfs -ls -R /
    $ alias hadoop='docker exec namenode hadoop'
    $ hadoop dfs -mkdir -p /tmp/test/app 
     WARNING: HADOOP_PREFIX has been replaced by HADOOP_HOME. Using value of HADOOP_PREFIX.
     mkdir: org.apache.hadoop.hdfs.server.namenode.SafeModeException: Cannot create directory /tmp/test/app. namenode is in safe mode.

    # 위와 같은 이슈 해결방법 - namenode가 safe 모드 설정됨. hadoop 2.9.2부터인가 추가된 기능임
    # (hdfs-site.xml에서 dfs.replication이 설정되면 safemode가 작동함)
    $ hadoop dfsadmin -safemode get | enter | leave

    $ hadoop dfs -mkdir -p /tmp/test/app
    $ hadoop dfs -ls -R /tmp
    $ hadoop dfs -rm -r /tmp/test/app
    ```
4. wordcount test

    참고: http://hadoop.apache.org/docs/r2.7.3/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html#Example:_WordCount_v1.0
    ```
    $ hadoop com.sun.tools.javac.Main WordCount.java
    $ jar cf WordCount.jar WordCount*.class

    # 여러가지 파일을 /tmp/test 밑에 insert 
    $ hadoop fs -put input.txt /tmp/test/ 
    $ hadoop jar WordCount.jar WordCount /tmp/test /output
    ```


## Hive
1. 구성
    + hadoop 3.2.1
    + hive v3.1.2
    + metastore mysql ~~mariadb 10.5~~
    + zookeeper

    참고(postgresql): https://github.com/big-data-europe/docker-hive   
    
    참고(mysql): https://github.com/kadensungbincho/de-hands-on/tree/main/docker-hadoop-poc

2. hive 확인 방법
    ```
    # 실제 hive에 tmp database가 hdfs에 어떤 위치에 쌓이게 된지 확인
    $ hadoop dfs -ls /user/hive/warehouse
      WARNING: Use of this script to execute dfs is deprecated.
      WARNING: Attempting to execute replacement "hdfs dfs" instead.

      Found 1 items
      drwxr-xr-x   - root supergroup          0 2021-04-06 00:54 /user/hive/warehouse/tmp2.db

    # 예제가 정상적으로 수행되면 다음과 같이 데이터가 partition
    $ docker exec namenode hadoop dfs -ls /user/hive/warehouse/tmp2.db/emp_part/
      WARNING: Use of this script to execute dfs is deprecated.
      WARNING: Attempting to execute replacement "hdfs dfs" instead.

      Found 2 items
      drwxr-xr-x   - root supergroup          0 2021-04-06 07:39 /user/hive/warehouse/tmp2.db/emp_part/year=2020
      drwxr-xr-x   - root supergroup          0 2021-04-06 07:39 /user/hive/warehouse/tmp2.db/emp_part/year=2021


    # hive container에서 beeline으로 확인
    $ hive
    > show [databases | table in databases] # DATABASES 및 TABLE 확인
    > show create database tmp; # 실제 데이터베이스가 어떻게 생성되었는지 확인
    > select * from tmp.hourly_employee;  # 데이터 확인
    ```

  + 설치시 에러 확인 방법) hive --hiveconf hive.root.logger=DEBUG,console

3. hive 셋팅시, docker-compose로 build할때 오류 처리 방법
    - 아래와 같이 docker-compose로 할 경우, 해당 디렉토리 + network 지정이 없을 경우 '[디렉토리명]_default'로 네트워크가 잡히면, hive-server에서는 illegal charater in hostname으로 잡힘. 따라서 network name에 _(언더바)가 안나오게 지정해야 함
    ```
    Caused by: org.apache.hadoop.hive.metastore.api.MetaException: Got exception: java.net.URISyntaxException Illegal character in hostname at index 37: thrift://hive-metastore.hadoopcluster_default:9083
        at org.apache.hadoop.hive.metastore.utils.MetaStoreUtils.logAndThrowMetaException(MetaStoreUtils.java:168) ~[hive-exec-3.1.2.jar:3.1.2]
        at org.apache.hadoop.hive.metastore.HiveMetaStoreClient.resolveUris(HiveMetaStoreClient.java:267) ~[hive-exec-3.1.2.jar:3.1.2]
        at org.apache.hadoop.hive.metastore.HiveMetaStoreClient.<init>(HiveMetaStoreClient.java:182) ~[hive-exec-3.1.2.jar:3.1.2]
        at org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient.<init>(SessionHiveMetaStoreClient.java:94) ~[hive-exec-3.1.2.jar:3.1.2]
        at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method) ~[?:1.8.0_292]
    ```
4. beeline으로 접속
- id,pw는 hive.env에 명시된 hive, hive임
    ```
    beeline> !connect jdbc:hive2://localhost:10000/default;auth=noSasl
    Connecting to jdbc:hive2://localhost:10000/default;auth=noSasl
    Enter username for jdbc:hive2://localhost:10000/default: hive
    Enter password for jdbc:hive2://localhost:10000/default: ****
    Connected to: Apache Hive (version 3.1.2)
    Driver: Hive JDBC (version 3.1.2)
    Transaction isolation: TRANSACTION_REPEATABLE_READ

    0: jdbc:hive2://localhost:10000/default> show databases;
    DEBUG : Acquired the compile lock.
    INFO  : Compiling command(queryId=root_20210629070337_741aca33-0669-4da5-a1af-043e7596c27f): show databases
    INFO  : Semantic Analysis Completed (retrial = false)
    INFO  : Returning Hive schema: Schema(fieldSchemas:[FieldSchema(name:database_name, type:string, comment:from deserializer)], properties:null)
    INFO  : Completed compiling command(queryId=root_20210629070337_741aca33-0669-4da5-a1af-043e7596c27f); Time taken: 0.031 seconds
    INFO  : Executing command(queryId=root_20210629070337_741aca33-0669-4da5-a1af-043e7596c27f): show databases
    INFO  : Starting task [Stage-0:DDL] in serial mode
    INFO  : Completed executing command(queryId=root_20210629070337_741aca33-0669-4da5-a1af-043e7596c27f); Time taken: 0.009 seconds
    INFO  : OK
    DEBUG : Shutting down query show databases
    +----------------+
    | database_name  |
    +----------------+
    | default        |
    | simple         |
    | tmp2           |
    +----------------+
    3 rows selected (0.068 seconds)

    ```



## hadoop 정보 확인
- hadoop 정보 확인
    * Namenode: http://<dockerhadoop_IP_address>:9870/dfshealth.html#tab-overview
    * History server: http://<dockerhadoop_IP_address>:8188/applicationhistory
    * Datanode: http://<dockerhadoop_IP_address>:19864/ (~19865,19866)
    * Nodemanager: http://<dockerhadoop_IP_address>:18042/node (~18043, 18044)
    * Resource manager: http://<dockerhadoop_IP_address>:8088/


## hadoop과 SimpleWeb 연동
- docker-compose 내에 network에 명시 만약, 따로 시스템을 구현할 경우 해당 부분 주석 필요

# build
```
./build.sh [start|stop]
```