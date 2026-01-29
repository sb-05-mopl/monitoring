# Monitoring

mopl 서비스의 모니터링 및 관측 인프라를 구성하는 프로젝트입니다. Prometheus, Grafana, 각종 Exporter를 Docker Compose로 운영하여 시스템 전반의 메트릭을 수집하고 시각화합니다.

## 아키텍처

```
Spring API ──┐
WebSocket ───┤
             ├──▶ Prometheus (9090) ──▶ Grafana (3000)
PostgreSQL ──┤        ▲
Elasticsearch┘        │
                  Pushgateway (9091) ◀── Batch Jobs
```

## 서비스 구성

| 서비스 | 이미지 | 포트 | 역할 |
|--------|--------|------|------|
| Prometheus | `prom/prometheus:v2.54.1` | 9090 | 메트릭 수집 및 저장 |
| Grafana | `grafana/grafana:11.1.4` | 3000 | 대시보드 시각화 |
| Pushgateway | `prom/pushgateway:latest` | 9091 | 배치 작업 메트릭 수신 |
| PostgreSQL Exporter | `prometheuscommunity/postgres-exporter` | 9187 | PostgreSQL 메트릭 수출 |
| Elasticsearch Exporter | `prometheuscommunity/elasticsearch-exporter` | 9114 | Elasticsearch 메트릭 수출 |

## 수집 대상 (Scrape Jobs)

| Job | 대상 | 메트릭 경로 |
|-----|------|-------------|
| `prometheus` | `prometheus:9090` | `/metrics` |
| `pushgateway` | `pushgateway:9091` | `/metrics` |
| `spring-api` | `host.docker.internal:80` | `/actuator/core/prometheus` |
| `websocket-server` | `host.docker.internal:80` | `/actuator/ws/prometheus` |
| `postgres` | `postgres-exporter:9187` | `/metrics` |
| `elasticsearch` | `elasticsearch-exporter:9114` | `/metrics` |

## Grafana 대시보드

사전 구성된 대시보드가 `grafana/dashboard/`에 포함되어 있습니다:

- **System Overview** - 인프라 및 시스템 수준 메트릭
- **Domain Overview** - 도메인별 애플리케이션 메트릭
- **Batch Job Monitoring** - 배치 작업 실행 모니터링
- **Content API 성능 모니터링** - Content API 성능 지표
- **Playlist API 성능 모니터링** - Playlist API 성능 지표
- **WatchingSession 성능 모니터링** - 시청 세션 추적 성능

## 실행 방법

### 사전 준비

프로젝트 루트에 `.env` 파일을 생성합니다:

```env
RUN_UID=<prometheus 실행 UID>
RUN_GID=<prometheus 실행 GID>
GRAFANA_ADMIN_USER=<grafana 관리자 계정>
GRAFANA_ADMIN_PASSWORD=<grafana 관리자 비밀번호>
```

### 데이터 디렉터리 생성

```bash
mkdir -p data/prometheus data/grafana
chown $RUN_UID:$RUN_GID data/prometheus
chown 472:472 data/grafana
```

### 컨테이너 실행

```bash
docker compose up -d
```

### 접속

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
- **Pushgateway**: http://localhost:9091

## 디렉터리 구조

```
monitoring/
├── docker-compose.yml          # 컨테이너 오케스트레이션
├── prometheus/
│   └── prometheus.yml          # Prometheus 스크레이프 설정
├── grafana/
│   ├── provisioning/
│   │   └── dashboards/
│   │       └── dashboards.yml  # 대시보드 프로비저닝 설정
│   └── dashboard/              # 사전 구성된 Grafana 대시보드 (JSON)
├── deploy/
│   └── monitoring/
│       ├── appspec.yml         # AWS CodeDeploy 설정
│       └── scripts/
│           └── starts.sh       # 컨테이너 시작 스크립트
└── data/                       # 런타임 데이터 (git 제외)
    ├── prometheus/
    └── grafana/
```

## 배포

GitHub Actions를 통해 `main` 및 `deploy` 브랜치에 push 시 자동 배포됩니다.

1. GitHub Actions에서 `.env` 생성 및 아티팩트 압축
2. S3에 업로드
3. AWS CodeDeploy로 EC2 인스턴스에 배포
