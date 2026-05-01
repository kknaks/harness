---
id: wiki-05
title: Refactor Layered Pattern
type: wiki
status: promoted
sources:
  - "[[sources-03-backend-rules]]"
related_to:
  - "[[wiki-01-code-review-pattern]]"
  - "[[wiki-04-tdd-cycle-pattern]]"
tags: [wiki]
categories: [refactoring, layered-architecture]
aliases: []
---

# Refactor Layered Pattern

> 합성·정리. sources-03 의 `refactor-layered.md` 부분에서 합성. **인간 검토 필요**.

## Summary

라우터 1 개 단위로 *4 계층 아키텍처* (Router / Service / Repository / Schema) 정렬 리팩토링 패턴. 각 계층의 책임·금지 사항을 명시 + grep 으로 위반 자동 검출. wiki-04 (tdd-cycle) 의 *Refactor 단계* 도구 + wiki-01 (code-review) 의 *사후 검토 시 grep 활용*.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 4 계층 책임표**

```
Router(HTTP)  →  Service(비즈니스)  →  Repository(DB 접근)  →  Model(ORM)
    ↕ Request/Response DTO        ↕ Internal DTO / ORM 인스턴스
```

| 계층 | 책임 (강제) | 금지 (강제) |
|------|-------------|-------------|
| Router | 경로·메서드·상태코드 / 인증·권한 Depends / DTO 파싱 / Service 호출 / Response DTO 반환 | DB 직접 호출 / Repository import / Model 응답 / 라우터 내 쿼리 헬퍼 |
| Schema | `*Request` / `*Response` / `*DTO` (Pydantic 등) / Model→Response 변환 | ORM 모델 import / Request·Response 클래스 공유 |
| Service | 비즈니스 로직 / 트랜잭션 조율 / Repository 조합 / Request → Response 변환 | DB 직접 호출 / `data: dict` 파라미터 / Model 직접 반환 / `commit()` |
| Repository | BaseRepository 상속 / 도메인 쿼리 확장 / Model 인스턴스 반환 | 비즈니스 룰 (상태 전이·권한 체크) / `commit()` |

**2) 정렬 절차 (라우터 1 개 단위)**

| 단계 | 본질 | 검증 |
|------|------|------|
| 사전 스캔 | 현재 어긋난 지점 grep 으로 카운트 | 위반 N 측정 |
| Schema 정렬 | Request / Response 분리 / Model→Response 변환 박기 | Schema 의 ORM import 0 |
| Service 정렬 | DB 접근 → Repository 위임 / `data: dict` → DTO | Service 의 select / db.execute 0 |
| Repository 정렬 | BaseRepository 재사용 / 도메인 쿼리만 추가 | 비즈니스 룰 0 |
| Router 정렬 | DB 호출 제거 / `response_model=` 추가 / 헬퍼 → Service | Router 의 select / db.execute 0 |
| 사후 검증 | grep 위반 0 + 회귀 테스트 100% | 0 violation + all green |

**3) grep 기반 위반 검출** (자동화 가능한 checklist)

```bash
# Router 의 DB 직접 호출
grep -n "select\|db\.execute\|db\.add\|db\.flush" {router-dir}/*

# Service 의 SQLAlchemy / ORM 직접 사용
grep -n "^from sqlalchemy import.*select\|await db\.execute\|db\.add(\|db\.flush(" {service-dir}/*

# Response DTO 누락 검출
grep -L "response_model=" {router-dir}/*
```

각 단계 끝에서 한 줄로 위반 0 보장. CI 후크 또는 PreToolUse 훅으로 강제 가능.

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

- **Router 위치**: `server/app/routers/<domain>.py`
- **Service 위치**: `server/app/services/<domain>.py`
- **Repository 위치**: `server/app/repositories/<domain>.py` (+ `repositories/base.py` BaseRepository)
- **Schema 위치**: `server/app/schemas/<domain>.py` (+ `schemas/common.py` 공통 Response)
- **리팩토링 진행 트래커**: `plan/refactor/re6-layered-architecture.md` (도메인별 4계층 정렬 진행 현황)
- **허용 예외**: `seeds/` (시드 직접 DB 조작) / `alembic/` (마이그레이션 ORM 우회) / `ws_*.py` (WebSocket 핸들러)

다른 프레임워크 슬롯 — Spring Boot (`controller/service/repository/entity`) / Express (`routes/services/dao/models`) / NestJS / Django REST / 등.

## References

- `sources-03-backend-rules` (refactor-layered.md 부분 — NEXUS `/refactor-layered` SKILL 박제)
- 자매 wiki: `wiki-01-code-review-pattern` (사후 검토 시 grep 도구 공유)
- 자매 wiki: `wiki-04-tdd-cycle-pattern` (Refactor 단계의 정렬 절차)
- ADR 계보: `[[adr-0005-refactor-layered-to-backend]]` (예정)
