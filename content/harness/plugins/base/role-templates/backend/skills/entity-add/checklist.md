# Entity Add Checklist

> 운영 체크리스트 — *어떤 순서로* (SSOT). 본질·룰은 `rules.md` SSOT.

## Pre-flight

- [ ] entity-name 식별 (snake_case / kebab-case 검증)
- [ ] 사용처 reference 로드:
  - `backend.md` (네이밍 / PK·FK 규칙 / 4계층 책임표)
  - `plan/erd/table-design.md` (BaseEntity Mixin 패턴)
  - `plan/erd/database-rules.md` (FK ON DELETE 정책 / 멀티테넌시 룰)
  - 사용처 디렉토리 (`<models-dir>` / `<schemas-dir>` / `<repositories-dir>`)
  - 부재 시 → fallback (Spring `@Entity` / Django `models.py` / TypeORM `@Entity` 자동 추정 + 사용자 확인)
- [ ] api-design 와의 호출 순서 — entity-add *먼저*, api-design *나중*
- [ ] 테스트 baseline — 현재 pass 카운트 측정

## Action — 1. Model

- [ ] `<models-dir>/{domain}.py` 작성
- [ ] BaseEntity 상속 (id UUID + timestamps + soft delete) — 또는 사용처 패턴
- [ ] ENUM 사용 안 함 — VARCHAR + Python Enum 검증
- [ ] FK ON DELETE 명시 (`CASCADE` / `SET NULL` / `RESTRICT`)
- [ ] 매핑 테이블이면 복합 PK
- [ ] 모델 import 가능 확인 (`python -c "from app.models import {Entity}"`)

## Action — 2. Migration

- [ ] `alembic revision --autogenerate -m "add {entity}"` (NEXUS prefix: `docker compose exec server uv run python -m alembic`)
- [ ] **autogenerate 한계 6종 검토** — `alembic-migration` SKILL §rules 참조 (인덱스 / FK action / server_default / 컬럼 reorder / VARCHAR 길이 / CHECK)
- [ ] `alembic upgrade head` 통과
- [ ] **Model + revision 같은 commit 으로 묶기** (분할 시 ORM ↔ DB 동기화 깨짐)

## Action — 3. Schema

- [ ] `<schemas-dir>/{domain}.py` 작성
- [ ] `*Request` / `*Response` 분리 (공유 X)
- [ ] `model_config = ConfigDict(from_attributes=True)` 설정 (Response 만)
- [ ] SQLAlchemy 모델 import 없음 (`from app.models import` grep 0)
- [ ] 부분 업데이트는 `model_dump(exclude_unset=True, exclude_none=True)` 패턴

## Action — 4. Repository

- [ ] `<repositories-dir>/{domain}_repo.py` 작성
- [ ] `class XRepository(BaseRepository[X]): pass` (단순 CRUD)
- [ ] 도메인 쿼리 (JOIN / 집계 / 재귀) 만 확장 메서드로
- [ ] 비즈니스 룰 (상태 전이 / 권한 체크) 0건
- [ ] `db.commit()` 호출 0건 (`db-transaction` reference 참조)

## Action — 5. Test

- [ ] `tdd-cycle` SKILL 호출 — Red → Green → Refactor
- [ ] `<tests-dir>/test_{domain}_api.py` 작성
- [ ] 회귀 — 기존 테스트 baseline 동일 또는 ↑

## Post-flight

- [ ] grep 흔한 실수 5종 모두 0:
  ```bash
  grep -nE "def [a-z_]+\(self.*\):" <models-dir>/{domain}.py     # Model 비즈니스 로직
  grep -nE "from app\.models" <schemas-dir>/{domain}.py           # Schema ORM import
  grep -nE "if .*\.(status|state) ==" <repositories-dir>/*.py     # Repo 비즈니스 룰
  grep -nE "db\.commit\(\)" <repositories-dir>/{domain}_repo.py   # Repo commit
  alembic upgrade head                                             # Migration 동기화
  ```
- [ ] `entity-add` 작업 보고 — §대상 + §5단 산출물 + §검증 + §다음 단계 (api-design)
- [ ] (선택) `/api-design <entity>` 인계 — 엔드포인트 단위로
