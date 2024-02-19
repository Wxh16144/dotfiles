const fs = require('fs-extra')
const readline = require('readline');
const glob = require('fast-glob');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '../backup');
const DEBUG = !!process.env.DESENSITIZE_DEBUG

function mask_sensitive_values(line) {
  if (typeof line !== 'string') return line;
  if (!line.startsWith('export')) return line;
  if (!line.includes('=')) return line;

  const [varName, varValue] = line.split('=').map(s => s.trim());
  const separator = ['-', '_']

  let maskedPart = 'xxxxxx',
    preservedPart = '';

  const delimPos = separator.map(sep => varValue.indexOf(sep)).find(pos => pos > 0)

  if (delimPos) preservedPart = varValue.slice(0, delimPos + 1);

  return `${varName}=${preservedPart}${maskedPart}`;
}

async function desensitize_env(envFile, desensitizedEnvFile = process.stdout) {
  const readStream = fs.createReadStream(envFile);
  const writeStream = desensitizedEnvFile === process.stdout
    ? desensitizedEnvFile
    : fs.createWriteStream(desensitizedEnvFile);

  const rl = readline.createInterface({
    input: readStream,
    crlfDelay: Infinity
  });

  for await (const line of rl) {
    const r = mask_sensitive_values(line);
    writeStream.write(r + '\n');
  }
}

async function main(files) {
  const isReal = DEBUG === false;
  const suffix = 'need_desensitize_tmp'
  const tipSuffix = isReal ? '' : ` (dry-run)`;

  for (const file of files) {
    let input = path.join(ROOT_DIR, file),
      output = process.stdout,
      cleanUpFiles = new Set();

    if (isReal) {
      output = input;

      const newInputPath = `${input}.${suffix}`
      fs.copySync(input, newInputPath, {
        overwrite: true,
      });
      cleanUpFiles.add(newInputPath);

      input = newInputPath;
    }

    await desensitize_env(input, output)
      .catch(err => {
        console.error(`❌ Desensitization failed for ${file}`, err);
        if (isReal) cleanUpFiles.add(output);
        process.exit(1);
      })
      .finally(() => {
        cleanUpFiles.forEach(fs.removeSync);
      });
  }

  console.log('✅ Desensitization complete' + (isReal ? '' : ' (dry-run)'));
}

const files = [
  '**/private_env.zsh',
]

const filesToProcess = files
  .map(file => glob.sync(file, {
    cwd: ROOT_DIR,
    dot: true,
    followSymbolicLinks: false
  })).flat();

console.log('🔍 Found files to desensitize', filesToProcess);

main(filesToProcess);
