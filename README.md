# promotheus-grafana
Prometheus configuration and Docker image for monitoring containers (cAdvisor), Grafana and exporters.

This repository contains a production-ready Prometheus container image and configuration that includes:
- Prometheus config: [prometheus.yml](prometheus.yml)
- Dockerfile to build the Prometheus image: [Dockerfile](Dockerfile)
- Alerting/recording rule files directory: [rules/](rules/)

Quick overview
- Prometheus listens on port `9090` and exposes a health endpoint at `/-/healthy`.
- Configuration files are copied into the image and stored under `/etc/prometheus/` in the container.
- The image drops privileges to `nobody` and enables the lifecycle API for live reloads.
- Default retention is `30d` and WAL compression is enabled.

Files
- [Dockerfile](Dockerfile) — builds a Prometheus image and copies `prometheus.yml` and `rules/`.
- [prometheus.yml](prometheus.yml) — scrape configs and rule file globs.
- [rules/](rules/) — directory for recording and alerting rules (YAML files). Add rule files here.

Quick start (Docker)

1) Build the image from the repository root:

```bash
docker build -t prometheus-custom .
```

2) Run Prometheus, mounting local config and rule files and persisting data:

```bash
docker run -d \
	--name prometheus \
	-p 9090:9090 \
	-v "$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
	-v "$(pwd)/rules:/etc/prometheus/rules:ro" \
	-v prometheus_data:/prometheus \
	prometheus-custom
```

Notes
- To add alerting or recording rules, create a `*.yml` file under the `rules/` directory. Prometheus loads files matching `rules/*.yml` as defined in `prometheus.yml`.
- To reload config or rules without restarting the container, use the lifecycle API:

```bash
# from the host
curl -X POST http://localhost:9090/-/reload
```

- Prometheus is configured to scrape common exporters (Grafana, cAdvisor, node_exporter, postgres_exporter) — edit `prometheus.yml` to adjust targets for your environment.

- Healthcheck is available at `http://<host>:9090/-/healthy` and the container `HEALTHCHECK` is defined in the `Dockerfile`.

Customization
- Retention, logging level, and storage options are set in the image `CMD` in the `Dockerfile`. If you run Prometheus directly (not via the image CMD), make sure to pass similar flags:

```
--storage.tsdb.path=/prometheus --storage.tsdb.retention.time=30d --storage.tsdb.wal-compression --web.enable-lifecycle --log.level=info
```

Docker Compose example

```yaml
version: '3.7'
services:
	prometheus:
		build: .
		ports:
			- "9090:9090"
		volumes:
			- ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
			- ./rules/:/etc/prometheus/rules/:ro
			- prometheus_data:/prometheus
		healthcheck:
			test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
			interval: 30s
			timeout: 10s
			retries: 3
		user: nobody

volumes:
	prometheus_data:
```

Troubleshooting
- If Prometheus reports missing rules, ensure rule files are valid YAML and follow Prometheus rule schema.
- If scrapes fail, verify network connectivity and that target exporters are reachable from the Prometheus host/container.

Contributing
- Add new `rules/*.yml` for alerts/recording rules and open a PR. Keep changes focused and validate rules with `promtool check rules`.

License
- See project owner for licensing (no license file included).

If you'd like, I can add a sample alert rule in `rules/` and a `docker-compose.yml` file — want me to add those?
