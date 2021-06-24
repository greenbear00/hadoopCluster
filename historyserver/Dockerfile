FROM hadoop-base:3.1.2

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8188/ || exit 1

ENV YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path=/hadoop/yarn/timeline
RUN mkdir -p /hadoop/yarn/timeline
VOLUME /hadoop/yarn/timeline

ADD run.sh /run.sh
RUN chmod a+x /run.sh
RUN sed -i 's/\r$//' /run.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/run.sh"]
