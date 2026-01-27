#!/bin/bash

echo "--------------- monitoring 시작 -----------------"

cd /home/ubuntu/monitoring

# 기존 컨테이너 중지 및 삭제
docker compose down --remove-orphans 2>/dev/null || true

# data 디렉토리 생성 (소유권 설정)
mkdir -p data/prometheus data/grafana

# 환경 변수에서 UID/GID 읽기
source .env

# prometheus 데이터 디렉토리 권한 설정
chown -R ${RUN_UID}:${RUN_GID} data/prometheus

# grafana 데이터 디렉토리 권한 설정 (grafana는 472:472 고정)
chown -R 472:472 data/grafana

# docker-compose로 컨테이너 시작
docker compose up -d

echo "--------------- monitoring 끝 ------------------"

# 컨테이너 상태 확인
sleep 5
docker ps | grep monitoring
