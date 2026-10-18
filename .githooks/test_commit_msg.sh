#!/usr/bin/env bash
# Tests for .githooks/commit-msg. Run: bash .githooks/test_commit_msg.sh
# Prints one line per case and exits 1 if any case gives the wrong answer.

hook="$(dirname "$0")/commit-msg"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
n=0

# expect <pass|fail> <name> <message, printf-style with \n>
expect() {
	local want="$1" name="$2" body="$3" got
	n=$((n + 1))
	printf "$body" > "$tmp/msg"
	if bash "$hook" "$tmp/msg" 2>/dev/null; then got=pass; else got=fail; fi
	if [ "$got" = "$want" ]; then
		echo "  PASS: $name ($want)"
	else
		echo "  FAIL: $name (wanted $want, got $got)"
		fails=$((fails + 1))
	fi
}

expect fail "plain 'stuff' is rejected" 'stuff\n'
expect pass "chore with a Task line" 'chore: add commit-msg hook\n\nTask: Y1-P0-S03\n'
expect fail "chore without a Task line" 'chore: add commit-msg hook\n'
expect pass "scope and a Story line" 'feat(story): add the shatter scene\n\nStory: EPIC-001-S02\n'
expect pass "breaking-change marker" 'fix(save)!: drop the v1 schema\n\nTask: Y1-P0-T07\n'
expect pass "Task line followed by Co-Authored-By" 'docs(qa): x\n\nTask: Y1-P0-T02\n\nCo-Authored-By: A <a@b.c>\n'
expect pass "refactor type" 'refactor: x\n\nTask: T\n'
expect pass "test type" 'test(context): x\n\nTask: T\n'
expect fail "unknown type" 'wip: halfway there\n\nTask: Y1-P0-S03\n'
expect fail "capitalised type" 'Feat: x\n\nTask: Y1-P0-S03\n'
expect fail "capitalised scope" 'feat(Story): x\n\nTask: Y1-P0-S03\n'
expect fail "no space after the colon" 'chore:x\n\nTask: Y1-P0-S03\n'
expect fail "empty description" 'chore: \n\nTask: Y1-P0-S03\n'
expect fail "Task only in a comment line" 'chore: x\n\n# Task: Y1-P0-S03\n'
expect fail "Task with no id" 'chore: x\n\nTask:\n'
expect pass "comment lines before the subject are ignored" '# Please enter the commit message\nchore: x\n\nTask: T\n'
expect pass "CRLF line endings (Windows editor)" 'chore: x\r\n\r\nTask: Y1-P0-S03\r\n'
expect pass "merge commit" "Merge branch 'main' into fix/phase0-playthrough-blockers\n"
expect pass "revert commit" 'Revert "feat(story): add the shatter scene"\n\nThis reverts commit 35b67e0.\n'
expect pass "fixup commit" 'fixup! chore: add commit-msg hook\n'
expect fail "empty message" ''

echo "COMMIT-MSG RESULT: $((n - fails)) passed, $fails failed"
[ "$fails" -eq 0 ]
