import assert from 'node:assert/strict';
import test from 'node:test';
import prepareRelease from './prepare-release.cjs';

function fixture({ tagSha, published = false, existing = false } = {}) {
  const writes = [], outputs = {};
  const missing = () => { throw Object.assign(new Error('missing'), { status: 404 }); };
  return {
    writes, outputs,
    args: {
      context: { repo: { owner: 'fixture', repo: 'openmeeting' }, sha: 'fixture-source-commit' },
      core: { setOutput: (key, value) => { outputs[key] = value; } },
      github: { rest: {
        git: {
          getRef: async () => tagSha ? { data: { object: { type: 'commit', sha: tagSha } } } : missing(),
          createRef: async (value) => { writes.push(value); return { data: value }; },
        },
        repos: {
          getReleaseByTag: async () => existing ? { data: { id: 71, draft: !published } } : missing(),
          createRelease: async (value) => { writes.push(value); return { data: { id: 72, ...value } }; },
        },
      } },
    },
  };
}

test('release tag and draft use the exact source commit and source version', async () => {
  const f = fixture(); await prepareRelease(f.args);
  assert.equal(f.writes[0].sha, f.args.context.sha);
  assert.equal(f.writes[0].ref, `refs/tags/v${f.outputs.version}`);
  assert.equal(f.writes[1].tag_name, `v${f.outputs.version}`);
  assert.equal(f.writes[1].target_commitish, f.args.context.sha);
  assert.equal(f.writes[1].draft, true);
});
test('same-commit draft can resume without creating another tag or release', async () => {
  const f = fixture({ tagSha: 'fixture-source-commit', existing: true }); await prepareRelease(f.args);
  assert.equal(f.outputs['release-id'], 71); assert.equal(f.writes.length, 0);
});
test('conflicting tags and published versions fail without modifying remote state', async () => {
  for (const options of [{ tagSha: 'another-commit' }, { tagSha: 'fixture-source-commit', existing: true, published: true }]) {
    const f = fixture(options); await assert.rejects(prepareRelease(f.args)); assert.equal(f.writes.length, 0);
  }
});
