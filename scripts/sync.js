#!/usr/bin/env node
const path = require('path');
const { execSync } = require('child_process');

process.env.BACKUP_CONFIG_FILE = path.resolve(__dirname, '../.backuprc');
process.env.BACKUP_CUSTOM_APP_DIR = path.resolve(__dirname, '../.backup');

// 你应该将 `process.env.HOME` 替换为你的名字，使用 `echo $HOME` 可以查看!!!
process.env.BACKUP_UPSTREAM_HOME ||= process.env.HOME;

const backupCli = require.resolve('@wuxh/backup-cli');

const args = process.argv.slice(2);
execSync(`node ${backupCli} ${args.join(' ')}`, { stdio: 'inherit' });
