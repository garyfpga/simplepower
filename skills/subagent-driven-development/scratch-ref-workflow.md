# Scratch Ref Workflow

Read this file before creating, diffing, deleting, or reporting Simple Power
scratch refs.

Scratch refs are coordinator-owned local review anchors. They are not branches,
accepted checkpoint commits, pushed refs, merged refs, rebased refs, worker
commits, or task commits. Workers, quick verifiers, review+fix agents, and
plan reviewers must not create, update, or delete them.

All scratch refs for one run live under:

```text
refs/simplepower/scratch/<run-id>/
```

The run id format is `YYYYMMDD-HHMMSS-<short-head>`, for example
`20260713-120102-a1b2c3d`. Record the run id in working notes and final
reporting whenever scratch refs are created.

## Phase Names

- Plan review:
  `refs/simplepower/scratch/<run-id>/plan-review/before`
  and `refs/simplepower/scratch/<run-id>/plan-review/after-<n>`
- Quick verifier:
  `refs/simplepower/scratch/<run-id>/quick-verifier/before`
  and `refs/simplepower/scratch/<run-id>/quick-verifier/after`
- Review+fix:
  `refs/simplepower/scratch/<run-id>/review-fix/before`
  and `refs/simplepower/scratch/<run-id>/review-fix/after`

A phase may omit an `after` ref only when no file changes happened in that
phase.

## Create A Scratch Ref

Use a temporary index so the real index and branch history are unchanged. Set
`approved_files` to the approved file list for the phase, `phase` to
`plan-review`, `quick-verifier`, or `review-fix`, and `label` to `before`,
`after`, or `after-<n>` as appropriate.

```bash
approved_files=(path/to/file1 path/to/file2)
phase="<phase>"
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

If scratch-ref creation fails, stop the review loop before relying on the
missing anchor.

## Diff Scratch Refs

Inspect the relevant scratch diff before creating the next accepted checkpoint
whenever quick-verifier tiny fixes or review+fix edits changed files.

```bash
git diff refs/simplepower/scratch/<run-id>/<phase>/<before-label> refs/simplepower/scratch/<run-id>/<phase>/<after-label> -- "${approved_files[@]}"
```

For revised plan review after blocking issues, provide the reviewer either this
exact diff command or an explicit diff summary based on the relevant refs.

## Cleanup After Successful Checkpoints

Delete only the phase whose accepted checkpoint has succeeded:

- delete `plan-review` refs after the accepted plan checkpoint succeeds;
- delete `quick-verifier` refs after the quick-verified implementation
  checkpoint succeeds, or after the no-empty-commit outcome is recorded as the
  successful checkpoint;
- delete `review-fix` refs after the final checkpoint succeeds, or after the
  no-empty-final-commit outcome is recorded as successful.

```bash
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
or a failed checkpoint commit, preserve scratch refs as evidence and report this
manual cleanup command instead of deleting refs:

```bash
git for-each-ref --format='%(refname)' "refs/simplepower/scratch/${run_id}/" | while read -r ref; do
  git update-ref -d "$ref"
done
```
