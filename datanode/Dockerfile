FROM hadoop-base:3.1.2


HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:9864/ || exit 1

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data
VOLUME /hadoop/dfs/data

ADD run.sh /run.sh
RUN chmod a+x /run.sh


RUN sed -i 's/\r$//' /run.sh

EXPOSE 9864 9866

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/run.sh"]
