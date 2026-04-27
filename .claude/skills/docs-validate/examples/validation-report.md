# Validation Report

생성: 2026-04-27 14:23

## Summary

- 검사 대상: 3 spec / 12 idea
- 통과: 10 / 13 검사
- 위반: 4

## Violations

### [missing-frontmatter] docs/idea/idea-08-quick-note.md
필수 필드 누락: `id`, `type`. `new-idea.sh` 로 생성하지 않은 듯.

### [missing-target] spec-02-cli-shape.related_to -> idea-99-typo
오타 또는 파일 누락.

### [cycle-supersedes] spec-04-runtime -> spec-02-cli-shape -> spec-04-runtime
서로 supersedes 선언. 둘 중 하나 제거 필요.

### [dup-owns] 'auth': spec-01-auth vs spec-03-auth
같은 topic 을 두 spec 이 SSOT 로 주장. 한쪽 deprecate 또는 `merge.sh`.

## Result

- exit 1
- `docs/_map.md` 재생성 안 됨
