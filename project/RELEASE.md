# Release handoff

Release scripts belong in the sibling **Scooby-Op** repository. Do not add release batch files, PowerShell release scripts, release payloads, or Visual Studio release projects to this website.

Use `Scooby-Op/release.bat` or `Scooby-Op/release/release.bat`; both launch `Scooby-Op/release/release.ps1`.

## Website paths

- Website root: `dogsite/`, containing `index.html`, `assets/`, `products/`, and `tools/`.
- Do not use the former `dogsite/site/` path.
- The optional TF2 `-UpdateWebsite` refresh validates required files and runs generators from the website root. It updates local files; website Git publication is separate.
- An ordinary game build does not require the website. No website compilation or solution file is required.
- Temporary website checks may use ignored `project/build/`; remove generated screenshots and reports when finished. Do not restore old `hidden_files/` output.

## Availability labels

The website displays **Dead** for Bodycam, PUBG, and Rainbow Six Siege, and **Coming soon** for MTA:SA. Bodycam has no free-access label. These fixed presentation labels are preserved when the operational status feed refreshes.

The loader feed retains its existing `online`, `updating`, `offline`, and `disabled` schema. Do not introduce `dead` or `coming soon` feed states without updating and validating its consumers. These website labels do not create loader products or grant access.

The existing `-StatusAction` commands manage the feed in `Scooby-Op/release/ProductStatus/`. Saving writes local copies; publishing is a separate explicit action.
