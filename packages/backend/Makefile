.PHONY: setup test dev start seed migrate lint clean

VENV := .venv
PY   := $(VENV)/bin/python
PIP  := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest

## 首次设置：创建虚拟环境并安装依赖
setup:
	python3 -m venv $(VENV)
	$(PIP) install -r requirements-dev.txt

## 运行测试
test:
	$(PYTEST) -v

## 快速测试（不打印详情）
test-q:
	$(PYTEST) -q

## 启动开发服务器（端口 3000，热重载）
dev:
	$(VENV)/bin/uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload

## 启动生产服务器
start:
	$(VENV)/bin/uvicorn app.main:app --host 0.0.0.0 --port 3000

## 运行种子脚本
seed:
	$(PY) scripts/seed.py

## 运行数据库迁移
migrate:
	$(VENV)/bin/alembic upgrade head
