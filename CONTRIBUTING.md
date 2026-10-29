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

-   `main`: our long-lived branch, upstream plus our changes. All work targets it.
-   `iden3/main`: an exact copy of upstream's `main`. Only ever fast-forwarded, never committed to.

### Syncing with upstream

1. Fast-forward `iden3/main` to `upstream/main` and push it.

   > [!NOTE]
   > If the fast-forward fails, something was committed to `iden3/main`.
   > Move it to a branch off `main` and reset `iden3/main` to `upstream/main`.

2. Rebase `main` onto `iden3/main` and force-push it.
3. Update downstream repos:
    -   [logos-blockchain-rust-rapidsnark](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark/blob/main/CONTRIBUTING.md#rapidsnark).
    -   [logos-blockchain-circuits](https://github.com/logos-blockchain/logos-blockchain-circuits): see its
        [CONTRIBUTING.md](https://github.com/logos-blockchain/logos-blockchain-circuits/blob/main/CONTRIBUTING.md#rapidsnark).
