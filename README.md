# qbTools — GUI Application

Qt 5.15 desktop application for controlling QBrobotics devices (SoftHand, SoftHand2, SoftHandPro, SoftClaw, qbMove).

## App Variants

The application ships in two variants, controlled by the `GUI_VARIANT` macro in `qbtool-gui-internal/qb_tabwidget.h`:

| Variant | Define | Description |
|---|---|---|
| **BASIC** | `GUI_BASIC` | Standard feature set |
| **COMPLETE** | `GUI_COMPLETE` | Full feature set |

## Building with Docker (AppImage)

The project uses an **Ubuntu Focal Docker container** with Qt 5.15 from the [beineri PPA](https://launchpad.net/~beineri/+archive/ubuntu/opt-qt-5.15.0-focal) to build self-contained Linux AppImages via [linuxdeployqt](https://github.com/probonopd/linuxdeployqt).

> **Why Focal?** linuxdeployqt enforces glibc ≤ 2.31 to ensure the resulting AppImage runs across supported Linux distributions. Ubuntu Focal (20.04) provides this glibc version.

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- X11 forwarding for display (handled automatically via volume mounts)

### Quick Start

```bash
cd GUI

# Build both BASIC and COMPLETE AppImages
docker compose up

# Build only BASIC
APP_TYPE=BASIC docker compose up

# Build only COMPLETE
APP_TYPE=COMPLETE docker compose up
```

The AppImages are produced in the `GUI/` directory:
- `qbTool-BASIC-x86_64.AppImage`
- `qbTool-COMPLETE-x86_64.AppImage`

### Build Process

Each variant build follows these steps:

1. **Set `GUI_VARIANT`** — `sed` updates the macro in `qb_tabwidget.h`
2. **Build** — `qmake` + `make` compile the Qt application
3. **Bundle libraries** — `libstdc++.so.6` and `libgcc_s.so.1` are force-bundled from the Qt PPA to prevent ABI mismatches on newer hosts
4. **Deploy** — `linuxdeployqt` bundles all Qt dependencies and creates the AppImage

### Running the AppImage

```bash
chmod +x qbTool-BASIC-x86_64.AppImage
./qbTool-BASIC-x86_64.AppImage
```

## Project Structure

```
GUI/
├── Dockerfile                          # Ubuntu Focal + Qt 5.15 (beineri PPA)
├── docker-compose.yml                  # Compose config, mounts X11 + /dev
├── deploy_app.sh                       # Build script (handles both variants)
├── linuxdeployqt-continuous-x86_64.AppImage
├── Appdir/                             # linuxdeployqt AppDir structure
│   ├── AppRun                          # Entry point -> usr/bin/qbTool
│   └── usr/share/application/qbTool.desktop
└── qbtool-gui-internal/                # Source code (git submodule)
    ├── qbtools.pro                     # Qt project file
    ├── qb_tabwidget.h                  # GUI_VARIANT toggle
    ├── main.cpp
    └── ...
```

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Segfault on Ubuntu 22.04 | Missing bundled `libstdc++`/`libgcc_s` | Ensure `deploy_app.sh` bundles them (it does by default) |
| `linuxdeployqt: host too new` | Running on glibc > 2.31 (e.g., Jammy) | Must build inside the Focal Docker container |
| `file command missing` | Missing `file` package in Docker | Already included in `Dockerfile` |
| X11 display not found | X11 socket not mounted | Ensure `/tmp/.X11-unix` volume is mounted |

## Notes

- **Rebuild from scratch:** `docker compose build --no-cache` to ensure a clean image.
- **Submodules:** The source code lives in `qbtool-gui-internal/` as a git submodule. Initialize with `git submodule update --init --recursive` before building outside Docker.
