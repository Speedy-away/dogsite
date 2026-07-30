# Repo Sync — dogsite ⇄ scooby-site

These two folders hold the **same website**:

| Repo | Local path | Remote |
| --- | --- | --- |
| `dogsite` | `C:\Users\whatw\OneDrive\Documents\GitHub\dogsite` | https://github.com/Speedy-away/dogsite |
| `scooby-site` | `C:\Users\whatw\OneDrive\Documents\GitHub\scooby-site` | https://github.com/Speedy-away/scooby-site |

Edit whichever one you like. Run the sync and the other one catches up — it works in **both directions**.

---

## Quick start

Make your edits in either folder, then:

```powershell
.\sync-site-repos.ps1
```

Or double-click **`sync-site-repos.bat`**.

That's it. The script figures out which side you changed, copies the files to the other side, commits both, and pushes both to GitHub.

To preview without changing anything:

```powershell
.\sync-site-repos.ps1 -DryRun
```

---

## Why it copies files instead of merging git

The two repos have **unrelated git histories** — separate `Initial commit`s, separate SHAs. Git can't merge them without an ugly `--allow-unrelated-histories` mess that would fight you on every sync.

So the script syncs the **working tree** (the actual files) and lets each repo keep its own independent history. The end result is what matters: both repos always hold byte-identical content.

Each repo keeps its own `.git` folder and its own remote. Those are never copied.

---

## How the direction is chosen

Running `.\sync-site-repos.ps1` with no arguments, the script picks the source in this order:

1. **One repo has uncommitted changes** → that one is the source.
2. **Both have uncommitted changes** → it stops and asks you to pick. Nothing is guessed, because guessing here would throw away real work.
3. **Both are clean but content differs** → the one with the newer commit wins. If the commits are the same age, it falls back to the newest file modification time.
4. **Both are clean and identical** → it reports "already in sync" and exits.

Override it whenever you want:

```powershell
.\sync-site-repos.ps1 -From dog       # dogsite     -> scooby-site
.\sync-site-repos.ps1 -From scooby    # scooby-site -> dogsite
```

---

## Options

| Flag | What it does |
| --- | --- |
| `-From dog` / `-From scooby` | Force the direction instead of auto-detecting |
| `-DryRun` | List every file that would be copied or deleted, then exit. Writes nothing, commits nothing |
| `-Pull` | `git pull --ff-only` both repos before syncing. Use this when you've edited files on the GitHub website |
| `-NoPush` | Commit locally but don't push to GitHub |
| `-Force` | Overwrite uncommitted changes in the target, and proceed even if a repo is behind its remote |
| `-Message "text"` | Custom commit message (default: `sync from <repo> (2026-07-31 06:30)`) |
| `-DogsitePath` / `-ScoobyPath` | Point at the repos manually if you move the folders apart |

---

## Safety rails

The script refuses to run rather than destroy work, in these cases:

- **The target has uncommitted changes.** A sync overwrites the target, so unsaved edits there would vanish. Commit or discard them first, or pass `-Force` if you genuinely want them gone.
- **A repo is behind its GitHub remote.** Pushing on top of that would silently bury commits made on github.com. Re-run with `-Pull` to fetch them first.
- **Both repos have uncommitted changes.** The direction is genuinely ambiguous — pick one with `-From`.

What is **never** copied between the repos:

- `.git/` — each repo's history and remote stay its own
- `backup/` — the local-only backup folder, deliberately kept off GitHub

Everything else is mirrored exactly, including `.claude/`, `assets/`, `docs/`, and all the HTML.

The copy is a true mirror (`robocopy /MIR`): a file you **delete** in the source gets deleted in the target too. That's intentional — otherwise deletions would never propagate and the repos would drift apart forever.

---

## Typical sessions

**Normal edit-and-sync**

```powershell
# edit index.html in dogsite
cd C:\Users\whatw\OneDrive\Documents\GitHub\dogsite
.\sync-site-repos.ps1
```

**You edited scooby-site instead** — same command, the script notices:

```powershell
cd C:\Users\whatw\OneDrive\Documents\GitHub\scooby-site
.\sync-site-repos.ps1
```

**You edited a file on github.com**

```powershell
.\sync-site-repos.ps1 -Pull
```

**Check before committing to anything**

```powershell
.\sync-site-repos.ps1 -DryRun
```

**Sync but hold off on pushing**

```powershell
.\sync-site-repos.ps1 -NoPush
```

---

## Heads-up: both repos publish the same domain

Both `CNAME` files contain `scoobymenu.cc`. Only one GitHub Pages site can actually serve that domain — the other will show a domain-conflict error in its Pages settings. That's fine if one repo is a mirror/backup, but it's worth knowing that syncing keeps this identical on purpose. If you ever want them on separate domains, `CNAME` would need to be excluded from the mirror.

---

## Optional: sync on a schedule

If you'd rather not run it by hand, register a Windows scheduled task that syncs every 30 minutes:

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\whatw\OneDrive\Documents\GitHub\dogsite\sync-site-repos.ps1" -Pull'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 30)
Register-ScheduledTask -TaskName 'SyncDogsiteScooby' -Action $action -Trigger $trigger
```

Remove it later with:

```powershell
Unregister-ScheduledTask -TaskName 'SyncDogsiteScooby' -Confirm:$false
```

Be aware this auto-commits and auto-pushes whatever is sitting in your working folder, so only set it up if that's what you want. Running it by hand is the safer default.

---

## If something goes wrong

Nothing here is unrecoverable — every sync commits before it copies, so the previous state is always in git.

```powershell
# See what changed in the last sync
git -C "C:\Users\whatw\OneDrive\Documents\GitHub\dogsite" log --oneline -5
git -C "C:\Users\whatw\OneDrive\Documents\GitHub\dogsite" show --stat HEAD

# Undo the last sync commit in a repo, keeping the files
git -C "<repo path>" reset --soft HEAD~1

# Throw away local changes and match GitHub again
git -C "<repo path>" fetch origin
git -C "<repo path>" reset --hard origin/main
```

To confirm the two repos really match:

```powershell
git -C "C:\Users\whatw\OneDrive\Documents\GitHub\dogsite"     rev-parse HEAD^{tree}
git -C "C:\Users\whatw\OneDrive\Documents\GitHub\scooby-site" rev-parse HEAD^{tree}
```

Identical hashes means identical content. The sync script prints this check at the end of every run.
