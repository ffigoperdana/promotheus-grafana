FROM prom/prometheus:latest

# bring in our production config
COPY prometheus.yml /etc/prometheus/prometheus.yml

# copy recording and alerting rules
COPY rules/ /etc/prometheus/rules/

# persist and serve metrics
EXPOSE 9090

# health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1

# drop privileges for better security
USER nobody

# run Prometheus with production configuration
# - config file location
# - storage path for metrics data  
# - 30 day retention period
# - WAL compression for better disk usage
# - lifecycle API for config reloads
# - external URL configuration
# - info level logging
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--storage.tsdb.retention.time=30d", \
     "--storage.tsdb.wal-compression", \
     "--web.enable-lifecycle", \
     "--web.external-url=http://localhost:9090", \
     "--log.level=info"]