# 구성
1. flask+uwsgi+nginx를 붙임
    - request --[http://localhost:8081]--> nginx --[8081:5000]--> flask+uwsgi [app]
2 logger 수집
    - flask 로그와 nginx 로그를 logstash를 통해서 elastic으로 전송
3. nifi 적용
    - nifi로 RDB 내용과 logger를 hadoop에 전송
4. hadoop 구성


## logger 셋팅
log 셋팅(nginx와 flask의 log를 logstash를 통하여 elastic으로 전송)
- logger에 대한 logstash pipleline관련하여 grok 문법에 대한 simulate는 kibana에서 [DevTools]->[Grok Debugger]에서 시뮬레이션 할 수 있음
    - logstash grok 문법 참조: https://github.com/logstash-plugins/logstash-patterns-core/blob/v2.0.5/patterns/grok-patterns#L86
- flask에서 내부 logging과 logstash로 log를 전송하게끔 구성함 
    - 실제 flask 내부에서 logstash.TCPLogstashHandler를 통해서 logstash 컨테이너에 log를 전송하게끔 하였음
    - (logstash pipeline관련 내용) .elk/logstash/pipeline/flask_log.conf
    - 로그 예:
        ```
        [flask 로그]
            2021-06-11 01:50:15,033 - web_stream - 192.168.176.1 - GET - OS - requested http://localhost:8080/ - INFO in log - session = no
            2021-06-22 06:34:47,821 - werkzeug - 192.168.240.1 - GET - OS - requested http://localhost:8080/ - INFO in log - session = None


        [logstash 로그]
            {
                "@version" => "1",
                "path" => "log",
                "method" => "GET",
                "loglevel" => "INFO",
                "host" => "flask.simpleweb_elastic",
                "timestamp" => "2021-06-11 01:50:15,018",
                "device" => "OS",
                "requested_url" => "http://localhost:8080/",
                "port" => 56660,
                "message" => "session = no",
                "@timestamp" => 2021-06-11T01:50:15.018Z,
                "clientip" => "192.168.176.1"
            }
        ```
- nginx의 access.log를 logstash로 전송하게끔 구성 (.elk/logstash/pipeline/flask_log.conf)
    - docker-compose 내에서 nginx의 /var/log/nginx 디렉토리에 있는 access.log 를 mount하여 logstash에서 file로 write하게끔 구성 
    - (logstash pipeline관련 내용) .elk/logstash/pipeline/simple_web_log.conf
    - 로그 예:
        ```
        [nginx access.log]
            192.168.176.1 - - [11/Jun/2021:01:50:15 +0000] "GET / HTTP/1.1" 200 280 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36" "-"

        [logstash]
            {
                "tags" => [
                    [0] "_dateparsefailure",
                    [1] "_geoip_lookup_failure"
                ],
                "agents" => {
                    "build" => "",
                    "os" => "Windows",
                    "patch" => "4472",
                    "minor" => "0",
                    "device" => "Other",
                    "os_name" => "Windows",
                    "major" => "91",
                    "name" => "Chrome"
                },
                "agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36",
                "@version" => "1",
                "http_version" => "1.1",
                "geoip" => {},
                "path" => "/var/log/nginx/access.log",
                "method" => "GET",
                "bytes" => "280",
                "response" => "200",
                "request" => "/",
                "host" => "b323ff9ed6aa",
                "referrer" => "-",
                "timestamp" => "11/Jun/2021:01:50:15 +0000",
                "message" => "192.168.176.1 - - [11/Jun/2021:01:50:15 +0000] \"GET / HTTP/1.1\" 200 280 \"-\" \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36\" \"-\"",
                "@timestamp" => 2021-06-11T01:50:15.823Z,
                "clientip" => "192.168.176.1"
            }

        ```



- elastic에 /web-YYYY.mm.dd 와 /access-YYYY.mm.dd로 로그가 쌓임
    ```
    [elastic에서 확인 방법]
        GET /web-2021.06.11/_search
        {
            "query": {
                "match_all": {}
            }
        }
    ```



## nifi 적용
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

## hadoop 셋팅
- hadoop 정보 확인
    * Namenode: http://<dockerhadoop_IP_address>:9870/dfshealth.html#tab-overview
    * History server: http://<dockerhadoop_IP_address>:8188/applicationhistory
    * Datanode: http://<dockerhadoop_IP_address>:19864/ (~19865,19866)
    * Nodemanager: http://<dockerhadoop_IP_address>:18042/node (~18043, 18044)
    * Resource manager: http://<dockerhadoop_IP_address>:8088/
- was와 hive-metastore-postgres와 postgres port 충돌이 발생하여, hive-metastore-postgres는 원래 5432로 설정하고, was에서는 5433으로 설정함 


# build
```
./build.sh [start|stop]
```