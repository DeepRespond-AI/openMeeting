const { readFileSync } = require('node:fs');

module.exports = async function prepareRelease({ github, context, core }) {
  const { owner, repo } = context.repo;
  const version = JSON.parse(readFileSync('frontend/src-tauri/tauri.conf.json', 'utf8')).version;
  const tag = `v${version}`;
  const missing = async (request) => {
    try { return (await request()).data; }
    catch (error) { if (error.status === 404) return null; throw error; }
  };
  const ref = await missing(() => github.rest.git.getRef({ owner, repo, ref: `tags/${tag}` }));
  if (ref) {
    let object = ref.object;
    for (let depth = 0; object.type === 'tag' && depth < 8; depth++) {
      object = (await github.rest.git.getTag({ owner, repo, tag_sha: object.sha })).data.object;
    }
    if (object.type !== 'commit' || object.sha !== context.sha) {
      throw new Error(`${tag} points to another commit. Bump the source version; existing tags are never moved.`);
    }
  }
  let release = await missing(() => github.rest.repos.getReleaseByTag({ owner, repo, tag }));
  if (release && !release.draft) throw new Error(`${tag} is already published. Bump the source version before releasing again.`);
  if (!ref) await github.rest.git.createRef({ owner, repo, ref: `refs/tags/${tag}`, sha: context.sha });
  if (!release) release = (await github.rest.repos.createRelease({
    owner, repo, tag_name: tag, target_commitish: context.sha,
    name: `OpenMeeting ${tag}`, draft: true, generate_release_notes: true,
  })).data;
  core.setOutput('version', version);
  core.setOutput('release-id', release.id);
};
