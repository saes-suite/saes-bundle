#!/usr/bin/env node
/**
 * Stamp CHANGELOG.md and bump version.txt and Tauri desktop configs (Cargo.toml & tauri.conf.json).
 *
 * Usage:
 *     node scripts/release_stamp.js --bump minor --author @username
 *     node scripts/release_stamp.js --dry-run
 *     node scripts/release_stamp.js --bump patch --author @ci-bot --date 2026-04-19
 */

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function execSafe(cmd, cwd = process.cwd()) {
  try {
    return execSync(cmd, { cwd, stdio: ["ignore", "pipe", "ignore"] })
      .toString()
      .trim();
  } catch (e) {
    return null;
  }
}

function getGitUser() {
  return execSafe("git log -1 --pretty=format:%an") || "unknown";
}

function getSubmodules() {
  const output = execSafe("git config --file .gitmodules --get-regexp path");
  if (!output) return [];
  return output
    .split("\n")
    .map((line) => line.trim().split(/\s+/)[1])
    .filter(Boolean);
}

function getBaseReleaseRef() {
  const versionCommit = execSafe("git log -n 1 --format=%H -- version.txt");
  if (versionCommit) return versionCommit;
  const latestTag = execSafe("git describe --tags --abbrev=0");
  if (latestTag) return latestTag;
  return execSafe("git rev-parse HEAD~1");
}

function getSubmoduleTreeSha(ref, subPath) {
  if (!ref) return null;
  const line = execSafe(`git ls-tree ${ref} -- ${subPath}`);
  if (!line) return null;
  const match = line.match(/^\d+\s+commit\s+([0-9a-f]{40})\s+/);
  return match ? match[1] : null;
}

function getSubmoduleVersionAtSha(subPath, sha) {
  if (!sha || !fs.existsSync(subPath)) return null;
  let version = execSafe(`git show ${sha}:version.txt`, subPath);
  if (!version) {
    execSafe(`git fetch --depth=1 origin ${sha}`, subPath);
    version = execSafe(`git show ${sha}:version.txt`, subPath);
  }
  return version ? version.replace("-SNAPSHOT", "").trim() : null;
}

function getSubmoduleUpdates() {
  const baseRef = getBaseReleaseRef();
  if (!baseRef) return [];

  const submodules = getSubmodules();
  const updates = [];

  for (const subPath of submodules) {
    const newSha = getSubmoduleTreeSha("HEAD", subPath);
    if (!newSha) continue;

    const oldSha = getSubmoduleTreeSha(baseRef, subPath);
    if (oldSha === newSha) continue;

    const newVersion =
      getSubmoduleVersionAtSha(subPath, newSha) ||
      (fs.existsSync(path.join(subPath, "version.txt"))
        ? fs.readFileSync(path.join(subPath, "version.txt"), "utf-8").trim()
        : null);
    const oldVersion = oldSha ? getSubmoduleVersionAtSha(subPath, oldSha) : null;

    if (!oldSha) {
      updates.push(
        newVersion
          ? `- **${subPath}**: \`${newVersion}\` (added)`
          : `- **${subPath}**: added (\`${newSha.slice(0, 7)}\`)`
      );
    } else if (oldVersion && newVersion && oldVersion !== newVersion) {
      updates.push(`- **${subPath}**: \`${oldVersion}\` → \`${newVersion}\``);
    } else if (newVersion) {
      updates.push(
        `- **${subPath}**: \`${newVersion}\` (updated to \`${newSha.slice(0, 7)}\`)`
      );
    } else {
      updates.push(
        `- **${subPath}**: \`${oldSha.slice(0, 7)}\` → \`${newSha.slice(0, 7)}\``
      );
    }
  }

  return updates;
}

function readSubmoduleVersion(subPath) {
  const versionFile = path.resolve(subPath, "version.txt");
  if (!fs.existsSync(versionFile)) return null;
  const raw = fs.readFileSync(versionFile, "utf-8").trim().replace("-SNAPSHOT", "");
  return raw || null;
}

function updateDockerCompose(composePath) {
  if (!fs.existsSync(composePath)) return;
  const v2Version = readSubmoduleVersion("saesV2");
  const aiVersion = readSubmoduleVersion("saes-ai");
  const uiVersion = readSubmoduleVersion("saes-ui");

  let content = fs.readFileSync(composePath, "utf-8");
  const original = content;

  if (v2Version) {
    content = content.replace(
      /(saesV2\[all\])(?:==[^\s'"]+)?/g,
      `$1==${v2Version}`
    );
  }
  if (aiVersion) {
    content = content.replace(
      /(https:\/\/github\.com\/saes-suite\/saes-ai\.git)(?:#[^\s'"]+)?/g,
      `$1#v${aiVersion}`
    );
  }
  if (uiVersion) {
    content = content.replace(
      /(https:\/\/github\.com\/saes-suite\/saes-ui\.git)(?:#[^\s'"]+)?/g,
      `$1#v${uiVersion}`
    );
  }

  if (content !== original) {
    fs.writeFileSync(composePath, content);
    console.log(
      `✅ docker-compose.yml updated (saesV2==${v2Version || "?"}, saes-ai#v${aiVersion || "?"}, saes-ui#v${uiVersion || "?"})`
    );
  }
}

function parseArgs() {
  const args = process.argv.slice(2);
  const parsed = {
    bump: "minor",
    author: null,
    date: null,
    dryRun: false,
    versionFile: "version.txt",
    changelogFile: "CHANGELOG.md",
    tauriConfFile: "src-tauri/tauri.conf.json",
    cargoFile: "src-tauri/Cargo.toml",
    dockerComposeFile: "docker-compose.yml",
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--bump") parsed.bump = args[++i];
    else if (arg === "--author") parsed.author = args[++i];
    else if (arg === "--date") parsed.date = args[++i];
    else if (arg === "--dry-run") parsed.dryRun = true;
    else if (arg === "--version-file") parsed.versionFile = args[++i];
    else if (arg === "--changelog-file") parsed.changelogFile = args[++i];
  }

  if (!["major", "minor", "patch"].includes(parsed.bump)) {
    parsed.bump = "minor";
  }
  return parsed;
}

function main() {
  const args = parseArgs();

  const versionPath = path.resolve(args.versionFile);
  if (!fs.existsSync(versionPath)) {
    console.error(`ERROR: ${versionPath} not found`);
    process.exit(1);
  }

  const current = fs.readFileSync(versionPath, "utf-8").trim();
  const baseVersion = current.replace("-SNAPSHOT", "");
  const parts = baseVersion.split(".");
  if (parts.length !== 3 || parts.some(isNaN)) {
    console.error(`ERROR: invalid semver format (got: ${baseVersion})`);
    process.exit(1);
  }

  let [major, minor, patch] = parts.map(Number);

  if (args.bump === "major") {
    major += 1;
    minor = 0;
    patch = 0;
  } else if (args.bump === "minor") {
    minor += 1;
    patch = 0;
  } else {
    patch += 1;
  }

  const release = `${major}.${minor}.${patch}`;
  const nextVersion = release;

  const author = args.author || getGitUser();
  const date = args.date || new Date().toISOString().split("T")[0];
  const submoduleUpdates = getSubmoduleUpdates();

  console.log("=== SAES Umbrella Release Stamp ===");
  console.log(`  Current:  ${current}`);
  console.log(`  Release:  ${release}`);
  console.log(`  Next:     ${nextVersion}`);
  console.log(`  Bump:     ${args.bump}`);
  console.log(`  Author:   ${author}`);
  console.log(`  Date:     ${date}`);
  if (submoduleUpdates.length > 0) {
    console.log("  Updated Repositories:");
    for (const line of submoduleUpdates) {
      console.log(`    ${line}`);
    }
  }

  if (args.dryRun) {
    console.log("\n[DRY RUN] No files modified.");
    return;
  }

  const changelogPath = path.resolve(args.changelogFile);
  if (!fs.existsSync(changelogPath)) {
    console.error(`ERROR: ${changelogPath} not found`);
    process.exit(1);
  }

  let content = fs.readFileSync(changelogPath, "utf-8");
  const unreleasedMarker = "## [Unreleased]";
  const releasedMarker = "## [Released]";

  const unreleasedIdx = content.indexOf(unreleasedMarker);
  const releasedIdx = content.indexOf(releasedMarker);

  if (unreleasedIdx === -1) {
    console.error(`ERROR: No '${unreleasedMarker}' section found in CHANGELOG.md`);
    process.exit(1);
  }

  if (releasedIdx === -1) {
    console.error(`ERROR: No '${releasedMarker}' section found in CHANGELOG.md`);
    process.exit(1);
  }

  const unreleasedEnd = unreleasedIdx + unreleasedMarker.length;
  const manualEntries = content.slice(unreleasedEnd, releasedIdx).trim();

  const sections = [];
  if (manualEntries) {
    sections.push(manualEntries);
  }
  if (submoduleUpdates.length > 0) {
    sections.push(`### Updated Repositories\n${submoduleUpdates.join("\n")}`);
  }

  const entries =
    sections.length > 0 ? sections.join("\n\n") : "- No updates for this version";

  const beforeUnreleased = content.slice(0, unreleasedIdx);
  const afterReleased = content
    .slice(releasedIdx + releasedMarker.length)
    .replace(/^\s+/, "");

  content = `${beforeUnreleased}${unreleasedMarker}\n\n${releasedMarker}\n\n## [${release}] — ${date} (${author})\n\n${entries}\n\n${afterReleased}`;
  fs.writeFileSync(changelogPath, content);

  fs.writeFileSync(versionPath, `${nextVersion}\n`);

  const tauriConfPath = path.resolve(args.tauriConfFile);
  if (fs.existsSync(tauriConfPath)) {
    const tauriConf = JSON.parse(fs.readFileSync(tauriConfPath, "utf-8"));
    tauriConf.version = nextVersion;
    fs.writeFileSync(tauriConfPath, JSON.stringify(tauriConf, null, 2) + "\n");
    console.log(`✅ src-tauri/tauri.conf.json version bumped to ${nextVersion}`);
  }

  const cargoPath = path.resolve(args.cargoFile);
  if (fs.existsSync(cargoPath)) {
    let cargoContent = fs.readFileSync(cargoPath, "utf-8");
    cargoContent = cargoContent.replace(/^version = ".*?"/m, `version = "${nextVersion}"`);
    fs.writeFileSync(cargoPath, cargoContent);
    console.log(`✅ src-tauri/Cargo.toml version bumped to ${nextVersion}`);
  }

  updateDockerCompose(path.resolve(args.dockerComposeFile));

  console.log(`\n✅ Changelog stamped as ${release}`);
  console.log(`✅ Version bumped to ${nextVersion}`);
}

main();
