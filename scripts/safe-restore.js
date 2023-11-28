const simpleGit = require('simple-git');
const { execSync } = require('child_process');
const path = require('path');

const script = path.resolve(__dirname, './sync.js');

const git = simpleGit({
  baseDir: path.join(__dirname, '..')
});

async function run() {
  if (!git.checkIsRepo()) {
    return console.log('Not a git repository');
  }

  const currentBranch = await git.branchLocal().then(({ current }) => current);
  const currentCommit = (await git.revparse(['HEAD'])).slice(0, 7);

  if (!(await git.status()).isClean()) {
    return console.log('Working tree is not clean');
  }

  // backup
  execSync(`node ${script} -f`, { stdio: 'inherit' });

  // stash
  if (!(await git.status()).isClean()) {
    const title = `WIP on ${currentBranch}(${currentCommit}): ${new Date().toLocaleString()}`.trim();

    await git.stash(['save', '-u', title]);
  }

  // safe restore
  process.env.BACKUP_FORCE_RESTORE = 'true';
  execSync(`node ${script} -rf`, { stdio: 'inherit' });
}

run();