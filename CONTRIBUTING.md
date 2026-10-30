# Contributing

## Fork maintenance

This repository is a fork of [iden3/rapidsnark](https://github.com/iden3/rapidsnark).

### Remotes

```bash
git remote add upstream https://github.com/iden3/rapidsnark.git
```

-   `origin`: this repository.
-   `upstream`: iden3/rapidsnark.

### Branches

-   `logos/v<x.y.z>`: our changes on top of upstream's `v<x.y.z>` tag, one branch per upstream version.
    The newest one is the default branch, and all work targets it.
-   `iden3/main`: an exact copy of upstream's `main`. Only ever fast-forwarded, never committed to.

`logos/*` branches are never rewritten, so their tags stay in their history.
PRs are merged by fast-forward, which GitHub's merge button can't do:

```bash
git push origin <pr-branch>:logos/v0.0.8
```

### Syncing with upstream

1. Fast-forward `iden3/main` to `upstream/main` and push it.

   > [!NOTE]
   > If the fast-forward fails, something was committed to `iden3/main`.
   > Move it to a branch off the newest `logos/*` branch and reset `iden3/main` to `upstream/main`.

2. When upstream tags a new version, e.g. `v0.0.9`, branch off the newest `logos/*` branch and rebase it onto the tag:

   ```bash
   git fetch upstream --tags
   git switch -c logos/v0.0.9 logos/v0.0.8
   git rebase --onto v0.0.9 v0.0.8
   git push origin logos/v0.0.9
   ```

3. Make `logos/v0.0.9` the default branch. `logos/v0.0.8` stays as it is.
4. Update downstream repos:
    -   [logos-blockchain-rust-rapidsnark](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark/blob/main/CONTRIBUTING.md#rapidsnark).
    -   [logos-blockchain-circuits](https://github.com/logos-blockchain/logos-blockchain-circuits): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-circuits/blob/main/CONTRIBUTING.md#rapidsnark).

## Releasing

Tags are `v<x.y.z>-logos.<n>` on `logos/v<x.y.z>`, e.g. `v0.0.8-logos.1` on `logos/v0.0.8`.
Release candidates add `-rc.<n>`.

1. Set `VERSION` to the new tag and merge it into the branch. CI fails if the tag doesn't match `VERSION`.
2. Tag the branch and push the tag:

   ```bash
   git tag v0.0.8-logos.1 origin/logos/v0.0.8
   git push origin v0.0.8-logos.1
   ```

3. CI builds and tests every platform, then creates a draft release with the archives.
   Tags with `-rc` are marked as pre-releases.
   It also commits the archive hashes to `rapidsnark-nix-hashes.json` on the branch and moves the tag onto that commit.
4. Review the draft and publish it.
