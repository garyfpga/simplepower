# Scratch Ref Workflow

Read this file before creating, diffing, deleting, or reporting Simple Power
scratch refs.

Use this workflow only when effective `skip_quick_verifier=false` selects the
FAST quick-verifier subagent. Effective `true` runs quick verification in the
main agent and creates no verifier run id or scratch refs.

Scratch refs are coordinator-owned local quick-verifier anchors. They are not
branches, accepted checkpoint commits, pushed refs, merged refs, rebased refs,
worker commits, or task commits. Workers and quick verifiers must not create,
update, delete, inspect, or manage them.

All scratch refs for one run live under:

```text
refs/simplepower/scratch/<run-id>/
```

The run id format is `YYYYMMDD-HHMMSS-<short-head>`, for example
`20260713-120102-a1b2c3d`. Record the run id in working notes and final
reporting whenever scratch refs are created.

## Phase Names

- Quick verifier:
  `refs/simplepower/scratch/<run-id>/quick-verifier/before`
  and `refs/simplepower/scratch/<run-id>/quick-verifier/after`

The `after` ref is omitted when the quick verifier changed no files.

## Create A Scratch Ref

Use a temporary index so the real index and branch history are unchanged. Set
`approved_files` to the approved file list, and `label` to `before` or `after`
as appropriate.

```bash
approved_files=(path/to/file1 path/to/file2)
phase="quick-verifier"
label="<label>"
run_id="${run_id:-$(date -u +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)}"
ref="refs/simplepower/scratch/${run_id}/${phase}/${label}"
tmp_index="$(mktemp)"
cleanup_tmp_index() { rm -f "$tmp_index"; }
trap cleanup_tmp_index EXIT

GIT_INDEX_FILE="$tmp_index" git read-tree HEAD
GIT_INDEX_FILE="$tmp_index" git add -- "${approved_files[@]}"
tree="$(GIT_INDEX_FILE="$tmp_index" git write-tree)"
commit="$(printf '%s\n' "simplepower scratch ${run_id} ${phase}/${label}" | git commit-tree "$tree" -p HEAD)"
git update-ref "$ref" "$commit"

rm -f "$tmp_index"
trap - EXIT
```

If scratch-ref creation fails, stop the verification loop before relying on
the missing anchor.

## Diff Scratch Refs

Inspect the quick-verifier scratch diff before coordinator review whenever the
quick verifier made tiny fixes.

```bash
git diff refs/simplepower/scratch/<run-id>/quick-verifier/before refs/simplepower/scratch/<run-id>/quick-verifier/after -- "${approved_files[@]}"
```

## Cleanup After Successful Final Checkpoint

Delete the quick-verifier refs only after the newest final reviewed/verified
completion checkpoint succeeds or after the no-empty-final-commit outcome is
recorded as successful. A technical-prerequisite or earlier execution-summary
commit does not trigger cleanup.

```bash
phase="quick-verifier"
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/${run_id}/${phase}" | while read -r ref; do
  git update-ref -d "$ref"
done
```

After final checkpoint cleanup, check for leftovers under the run id:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/${run_id}/"
```

## Preserve Evidence On Blockers Or Failed Checkpoints

On user direction, a blocker, scratch-ref creation failure after partial refs,
or a failed checkpoint, preserve scratch refs as evidence and report this
manual cleanup command instead of deleting refs:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/${run_id}/" | while read -r ref; do
  git update-ref -d "$ref"
done
```
