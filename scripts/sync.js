#!/usr/bin/env node
const path = require('path');
const { execSync } = require('child_process');

process.env.BACKUP_CONFIG_FILE = path.resolve(__dirname, '../.backuprc');
process.env.BACKUP_CUSTOM_APP_DIR = path.resolve(__dirname, '../.backup');
process.env.BACKUP_UPSTREAM_HOME = '/Users/wuxh' // need >= 1.9.0

const backupCli = require.resolve('@wuxh/backup-cli');

const args = process.argv.slice(2);
execSync(`node ${backupCli} ${args.join(' ')}`, { stdio: 'inherit' });
