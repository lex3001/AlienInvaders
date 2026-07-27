# Web Deployment Guide

This guide explains how to deploy the Alien Invaders game to GitHub Pages.

## Quick Start

### Option 1: One-Click Manual Deploy (Recommended for local testing)

```bash
cd godot
./deploy.sh
```

This script will:
1. Export the game to HTML5
2. Save it to the `/docs` folder
3. Commit changes to git
4. Push to GitHub

Your game will be live at: `https://lex3001.github.io/AlienInvaders/`

### Option 2: Automatic Deploy (Recommended for production)

The repository includes a GitHub Actions workflow that automatically:
- Exports the game whenever you push changes to `godot/` folder
- Commits the build to `/docs` folder
- Publishes to GitHub Pages

**No action needed!** Just push your changes and the deployment happens automatically.

## Setup GitHub Pages

If not already configured:

1. Go to your repository Settings → Pages
2. Under "Source", select:
   - Branch: `main`
   - Folder: `/docs`
3. Click "Save"

Your site will be published at: `https://lex3001.github.io/AlienInvaders/`

## Manual Export (Advanced)

If you prefer to export manually:

1. Open Godot and load the project
2. Go to **Project → Export**
3. Select the **"Web"** preset (pre-configured)
4. Click **"Export Project"**
5. Export to `/docs/index.html`
6. Commit and push:
   ```bash
   git add docs/
   git commit -m "Deploy: Updated web build"
   git push origin main
   ```

## Troubleshooting

### Deploy script not found
```bash
ls -la godot/deploy.sh  # Check if file exists
chmod +x godot/deploy.sh  # Make sure it's executable
```

### Godot command not found
Make sure Godot is installed and in your PATH:
```bash
which godot
godot --version
```

### GitHub Actions failing
Check the workflow status:
- Go to Actions tab in GitHub
- Click the failed workflow
- View logs for error details

### Site not updating
- Check that files are actually in `/docs` folder
- Clear your browser cache
- Wait a few seconds for GitHub Pages to rebuild

## Files

- `godot/export_presets.cfg` - HTML5 export configuration
- `godot/deploy.sh` - One-click deploy script
- `.github/workflows/deploy.yml` - Automatic deployment workflow

## Testing Locally

Before deploying, test the web build locally:

```bash
cd docs
# Start a local web server
python3 -m http.server 8000
```

Then visit: `http://localhost:8000`
