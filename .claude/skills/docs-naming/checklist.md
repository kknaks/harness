# Docs-Naming Checklist

## 새 idea 생성

### Pre-flight

- [ ] 사용자가 준 메모·요청 핵심을 1줄 title 로 압축 (kebab-case 가능한 형태)
- [ ] 같은 주제의 기존 idea 가 있는지 확인 (`docs/idea/` 훑어보기 + `_map.md`)
  - 있으면 → 신규 X, 기존 idea 본문에 추가 또는 사용자 확인

### Create

- [ ] `scripts/new-idea.sh "<title>"` 실행 → 생성 경로 출력
- [ ] 출력 경로 (`docs/idea/idea-NN-<slug>.md`) 가 NN 단조 증가 + slug kebab-case 인지 확인
- [ ] frontmatter 최소 필드 (`id`, `type: idea`) 박혀있는지 확인

### Body

- [ ] 사용자가 준 메모를 본문에 작성 (그대로 박는 게 default — 정제는 spec 단계)
- [ ] 다른 idea/spec 와 관계가 있으면 frontmatter 에 추가:
  - `related_to: [[...]]` — 양방향 소프트 링크
  - `supersedes: [[...]]` — 이 idea 가 대체하는 다른 idea/spec
  - `depends_on: [[...]]` — 이 idea 가 의존하는 spec

### Post-flight

- [ ] `docs-validate/scripts/validate.sh` 통과 (PostToolUse 훅이 자동 호출하기도 함)
- [ ] 사용자에게 보고: 경로, 관계 필드 박힘 여부, _map 갱신

---

## 파일명 / 스키마 점검

기존 자산 정리 시:
- [ ] 파일명 패턴 매칭 (`{type}-NN-{slug}.md` / `adr-NNNN-{slug}.md`)
- [ ] frontmatter `id` 가 파일명 NN 과 동일
- [ ] `type` 이 디렉토리와 일치
- [ ] kebab-case slug (영문 소문자·숫자·`-`)
- [ ] 번호 재사용 X (폐기되어도 비워둠)

위반 시 — `docs-validate` 가 자동 catch (R1-R10). 사후 수정.
