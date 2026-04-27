# Validate Checklist

`scripts/validate.sh` 가 자동 검사 + `_map.md` 재생성. 수동 검토 시 순서.

## Frontmatter

- [ ] 모든 `docs/idea/idea-*.md` 가 `id`, `type` 보유
- [ ] 모든 `docs/spec/spec-*.md` 가 9개 필수 필드 보유
- [ ] `type` 이 디렉토리와 일치

## Uniqueness

- [ ] `id` 중복 없음 (전체)
- [ ] `owns` 중복 없음 (spec)

## Sources (lineage)

- [ ] spec.sources 비어있지 않음
- [ ] 모든 sources 항목이 `[[idea-...]]` (spec→idea 만)

## Relationship links

- [ ] `related_to`, `supersedes`, `depends_on` 의 모든 위키링크가 실재 파일
- [ ] 자기 자신 가리키는 링크 없음

## DAG

- [ ] `supersedes` 사이클 없음
- [ ] `depends_on` 사이클 없음

## Map

- [ ] 검사 통과 시 `docs/_map.md` 재생성됨
- [ ] Relations 섹션의 엣지 카운트가 합리적
- [ ] `⚠ multi-spec` 항목은 사용자에게 의도 확인

## Reporting

- [ ] 위반 코드별 분류
- [ ] 자동 수정 제안 + 승인 받기
- [ ] exit 1 → 호출자가 실패 인지
