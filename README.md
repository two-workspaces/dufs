# Deploy and Host Dufs File Server on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/file-server?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=file-server)

Dufs is a small, fast file server written in Rust. Open it in a browser to upload files and whole folders by drag and drop, download any folder as a zip, search, create and edit text files, and move or delete things. It also speaks WebDAV, so you can mount it as a network drive on Windows, macOS, Linux, iOS and Android, and it works from `curl` with plain HTTP. This template runs dufs 0.47.0 on Railway with a persistent volume and a login, so your files survive redeploys and nobody else can change them.

## About Hosting Dufs File Server

Deploy, wait for the green check, and open the Railway domain. Log in with `USERNAME` (default `admin`) and the generated `PASSWORD`, both on the service's Variables tab.

**Everything you upload lives on the volume at `/data`.** Redeploys, restarts and dufs upgrades keep it. The volume's size depends on your Railway plan, and you can grow it in the service's settings.

**Change the password** by editing `PASSWORD` on the Variables tab; Railway restarts the service with it. Any characters work.

**Share files publicly:** set `PUBLIC_READ=true`. Anyone with the link can then browse and download, while only your account can upload, edit or delete.

**Mount it as a drive (WebDAV):** use your Railway domain as the server address, `https://your-app.up.railway.app`, with the same username and password.
- **macOS Finder:** Go → Connect to Server.
- **Windows:** Map network drive → "Connect to a Web site…", or `net use Z: https://your-app.up.railway.app /user:admin`.
- **Linux:** `davs://your-app.up.railway.app` in Files, or rclone with `type = webdav`.
- **Phones:** any WebDAV client, such as the Files app's server option on iOS or Solid Explorer on Android.

**From scripts:**

```sh
curl -u admin:PASSWORD -T report.pdf https://your-app.up.railway.app/reports/report.pdf   # upload
curl -u admin:PASSWORD -O https://your-app.up.railway.app/reports/report.pdf             # download
curl -u admin:PASSWORD "https://your-app.up.railway.app/reports?zip" -o reports.zip      # folder as zip
curl -u admin:PASSWORD "https://your-app.up.railway.app/?q=report"                       # search
curl -u admin:PASSWORD -X DELETE https://your-app.up.railway.app/reports/report.pdf      # delete
```

Large uploads and downloads can be resumed.

**More options:** dufs reads any `DUFS_*` variable. For example, `DUFS_ENABLE_CORS=true` lets web apps on other domains fetch files, `DUFS_RENDER_TRY_INDEX=true` serves `index.html` in folders that have one, so it works as a static website host, and `DUFS_HIDDEN=*.tmp,.git` hides names from listings. To write dufs's own access rules yourself, such as several accounts or per-folder permissions, set `DUFS_AUTH`, e.g. `admin:secret@/:rw|guest:guest@/public`. It replaces `USERNAME`, `PASSWORD` and `PUBLIC_READ`.

## Common Use Cases

- A private file drop and download point you can reach from any device
- A WebDAV network drive for backups, rclone, Obsidian or Zotero sync, or office apps
- Sharing builds, datasets, videos or large files by link instead of email
- Hosting a static website or the assets for one
- Moving files in and out of other Railway services over HTTP with `curl`

## Dependencies for Dufs File Server Hosting

- None. One service with one volume.

### Deployment Dependencies

- [Dufs on GitHub](https://github.com/sigoden/dufs)
- [Template source](https://github.com/two-workspaces/dufs)

### Implementation Details

- **Login:** built from `USERNAME` and `PASSWORD` on every boot, with read and write on everything. The browser UI and WebDAV both use basic auth over Railway's HTTPS. A password holding `|` or `@/`, which dufs's rule format can't carry, is stored as a SHA-512 hash instead.
- **Never open by accident:** if `PASSWORD` is emptied, the service still starts but with a random one-off password printed in the deploy logs, not with open access.
- **Permissions:** upload, delete, search and folder-as-zip are on. Symlinks out of the served folder are off.
- **Volume:** mounted at `/data`. The volume's own `lost+found` folder is hidden from listings.
- **Memory:** dufs itself needs a few MB. Linux keeps files it has served in its page cache, which Railway counts as the service's memory, so the template drops that cache for served files every 15 minutes.
- **Healthcheck:** `/__dufs__/health`, which needs no login.
- **Image:** upstream's `sigoden/dufs:v0.47.0` binary, pinned, on Alpine with a small entrypoint that maps the variables.

## Why Deploy Dufs File Server on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Dufs File Server on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
