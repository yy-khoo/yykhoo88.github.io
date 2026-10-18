# YY technical notes

A minimal Quarto website for concise notes on quantitative finance, derivatives, model validation, market risk, and numerical methods. It is designed for GitHub Pages and includes one executable Python note to verify the publishing stack.

## Local setup

Install these tools:

- [Quarto](https://quarto.org/docs/get-started/)
- Python 3.10 or newer

Create and activate a virtual environment, then install the small Python dependency set:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

On macOS or Linux, activate the environment with `source .venv/bin/activate`.

## Preview and render

Start a local preview that refreshes as files change:

```console
quarto preview
```

Render the complete site to `_site/`:

```console
quarto render
```

For a quick environment check, run `quarto check jupyter`.

## Deploy to GitHub Pages

Publishing is manual: source pushes do not render or publish the website.

### PowerShell shortcut

Stop any running `quarto preview` with **Ctrl+C** before publishing; simultaneous renders can conflict over generated HTML files.

Create an empty GitHub repository first, then run `./publish.ps1` from PowerShell.
On the first run it asks for the repository URL. Alternatively:

```powershell
./publish.ps1 -RepositoryUrl https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
```

The script commits website sources, pushes the current source branch, and runs Quarto's manual publisher. GitHub may prompt you to sign in. It accepts already-staged website sources so interrupted runs can be retried, but stops if unrelated files are staged or a push fails, and never force-pushes. After the first publication, select **gh-pages / (root)** in GitHub Pages settings. Run `./publish.ps1` again for future releases.

### Individual steps

1. Create an empty public GitHub repository. Use `YOUR_USERNAME.github.io` for a personal homepage, or another name for a project website.
2. Connect this local repository and push the source (replace the URL):

   ```powershell
   git add README.md .gitignore _quarto.yml index.qmd about.qmd assets notes src requirements.txt
   git commit -m "Initial technical notes website"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
   git push -u origin main
   ```

3. In a PowerShell terminal in the project folder, select the Python environment and publish:

   ```powershell
   $env:QUARTO_PYTHON = (Resolve-Path .venv/Scripts/python.exe).Path
   ./.tools/quarto/bin/quarto.cmd publish gh-pages
   ```

   If Quarto is installed globally, `quarto publish gh-pages` also works. Authenticate with GitHub if prompted. The command renders locally and pushes the generated site to the `gh-pages` branch.
4. Open the repository's **Settings → Pages**. Select **Deploy from a branch**, branch **gh-pages**, folder **/ (root)**, and save.
5. Visit the URL shown in Pages settings once deployment finishes. A personal homepage uses `https://YOUR_USERNAME.github.io/`; a project site uses `https://YOUR_USERNAME.github.io/YOUR_REPOSITORY/`.

For later updates, commit and push your source changes, then run the publish command again when ready to release. GitHub still runs its built-in Pages deployment after the published branch changes; there is no custom render-on-push workflow in this project.

Official guide: https://quarto.org/docs/publishing/github-pages.html

No base URL is hard-coded, so the same configuration works for both `username.github.io` and `username.github.io/repository-name` repositories.

## Earlier website content

All articles live in `notes/`, organised by subject categories, including the historical computing and SEIR articles. `projects.qmd` replaces the older standalone project library. Migrated articles retain their original metadata dates and store their images alongside the article. The SEIR page preserves its historical outputs with a prominent parameterisation correction rather than presenting them as newly validated results.

`OLD PAGES/` remains a local reference copy and is excluded from the project's explicit render list and publishing script's source list. The former Hello World post, unused legacy assets, old analytics, and broken download placeholders are not migrated.

## Add a note

Create a folder under `notes/` and add an `index.qmd` file with metadata like this:

```yaml
---
title: "Note title"
date: YYYY-MM-DD
description: "One-sentence summary."
categories:
  - Options
---
```

The Notes page discovers matching documents automatically. Add `jupyter: python3` when the note contains executable Python cells.

