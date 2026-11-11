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
PRs are squash-merged, so each one is a single commit that is easy to rebase onto a new upstream version.

### Syncing with upstream

1. Fast-forward `iden3/main` to `upstream/main` and push it.

   > [!NOTE]
   > If the fast-forward fails, something was committed to `iden3/main`.
   > Move it to a branch off the newest `logos/*` branch and reset `iden3/main` to `upstream/main`.

2. When upstream tags a new version, e.g. `v0.0.9`, branch off the newest `logos/*` branch and rebase it onto the tag:

   ```bash
   git fetch origin
   git fetch upstream --tags
   git switch -c logos/v0.0.9 origin/logos/v0.0.8
   git rebase --onto v0.0.9 v0.0.8
   git push origin logos/v0.0.9
   ```

   > [!NOTE]
   > If upstream changed the `depends/ffiasm` or `depends/json` submodule, set the same commit in its `flake.nix` input
   > and run `nix flake lock`. CI checks that they match.

3. Make `logos/v0.0.9` the default branch. `logos/v0.0.8` stays as it is.
4. Update downstream repos:
    -   [logos-blockchain-rust-rapidsnark](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark/blob/main/CONTRIBUTING.md#rapidsnark).
    -   [logos-blockchain-circuits](https://github.com/logos-blockchain/logos-blockchain-circuits): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-circuits/blob/main/CONTRIBUTING.md#rapidsnark).

## Releasing

Tags are `v<x.y.z>-logos.<n>` on `logos/v<x.y.z>`, e.g. `v0.0.8-logos.1` on `logos/v0.0.8`.
Release candidates add `-rc.<n>`.

1. Tag the branch's last commit and push the tag:

   ```bash
   git fetch origin
   git tag v0.0.8-logos.1 origin/logos/v0.0.8
   git push origin v0.0.8-logos.1
   ```

2. CI checks the tag's format, builds and tests every platform, then creates a draft release with the archives.
   Tags with `-rc` are marked as pre-releases.
3. CI commits `VERSION` and the archive hashes in `rapidsnark-nix-hashes.json` to the branch, then moves the tag onto that commit.
   The flake reads both files to download the release, because it can't read its own tag.
   Don't edit them by hand.

   > [!NOTE]
   > This fails if the branch got new commits after the tag. Then tag the new last commit with the next version, e.g. `-rc.2`.

4. Review the draft and publish it.
