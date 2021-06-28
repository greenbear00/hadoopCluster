FROM hadoop-base:3.2.1

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8088/ || exit 1

ADD run.sh /run.sh
RUN chmod a+x /run.sh
RUN sed -i 's/\r$//' /run.sh

EXPOSE 8088 8032

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/run.sh"]
