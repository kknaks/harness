# Promote / Merge Checklist

## 새 spec 으로 승격

### Pre-flight

- [ ] 대상 idea 파일 존재 + `id`/`type` 프론트매터 있음
- [ ] `owns` topic 이름 사용자와 합의
- [ ] 같은 `owns` 의 spec 이 이미 있는지 확인 (`_map.md` 또는 grep)
  - 있으면 → 병합 경로로 전환

### Promotion

- [ ] 다음 spec 번호 산정 (max + 1)
- [ ] `scripts/promote.sh <idea>` 실행
- [ ] 9개 필수 필드 채워짐: id, title, type:spec, status:draft, created, updated, sources, owns, tags
- [ ] (선택) `related_to`/`supersedes`/`depends_on` 추가
- [ ] 본문 스캐폴드 (Goal/Non-goals/Design/Open Questions)

### Post-flight

- [ ] `docs-validate/scripts/validate.sh` 통과
- [ ] 사용자에게 보고: 경로, owns, _map 갱신 사실

---

## 기존 spec 에 병합

### Pre-flight

- [ ] idea + spec 둘 다 존재
- [ ] 사용자에게 "정말 같은 주제?" 한 번 확인

### Merge

- [ ] `scripts/merge.sh <idea> <spec>` 실행 (멱등)
- [ ] spec 의 `sources` 에 idea 추가됐는지 확인
- [ ] `updated` 가 오늘 날짜
- [ ] 본문 통합 (수동) — idea 의 핵심을 spec 본문에 반영

### Post-flight

- [ ] `docs-validate/scripts/validate.sh` 통과
- [ ] 사용자에게 보고: 새 sources 리스트, _map 변경

---

## 위반 처리

검증에서 위반 나오면:
- `missing-target` → 위키링크 오타 또는 파일 누락 확인
- `cycle-supersedes`/`cycle-depends_on` → 순환 끊기
- `dup-owns` → 어느 spec 이 진짜 owner 인지 결정, 다른 쪽 deprecate 또는 병합
- `self-link` → 자기 자신을 가리키는 링크 제거
