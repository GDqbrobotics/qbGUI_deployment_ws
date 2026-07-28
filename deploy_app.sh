#!/bin/bash
set -e

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$parent_path"

SRC="qbtool-gui-internal/qb_tabwidget.h"

# Determine which variants to build
# APP_TYPE env var: "ALL" (default), "BASIC", or "COMPLETE"
BUILD_VARIANT="${APP_TYPE:-ALL}"

case "$BUILD_VARIANT" in
    BASIC|COMPLETE)
        VARIANTS=("$BUILD_VARIANT")
        ;;
    ALL|"")
        VARIANTS=("BASIC" "COMPLETE")
        ;;
    *)
        echo "ERROR: unknown APP_TYPE='$BUILD_VARIANT' (use BASIC, COMPLETE, or ALL)"
        exit 1
        ;;
esac

echo "=== Will build variants: ${VARIANTS[*]} ==="

for VARIANT in "${VARIANTS[@]}"; do
    echo ""
    echo "=========================================="
    echo "  Building qbTool ($VARIANT variant)"
    echo "=========================================="

    # Set GUI_VARIANT in the header via sed
    echo "=== Setting GUI_VARIANT = GUI_$VARIANT ==="
    sed -i "s/^#define GUI_VARIANT GUI_[A-Z_]\+/#define GUI_VARIANT GUI_${VARIANT}/" "$SRC"

    # Verify the change
    grep "^#define GUI_VARIANT" "$SRC"

    # Clean old binaries and bundled libs
    rm -rf Appdir/usr/bin/qbTool
    rm -rf Appdir/usr/lib
    rm -rf Appdir/usr/plugins
    rm -rf Appdir/usr/translations
    mkdir Appdir/usr/lib
    mkdir Appdir/usr/plugins
    mkdir Appdir/usr/translations

    # Build
    cd qbtool-gui-internal


    echo "=== Running qmake ==="
    if [$VARIANT = "COMPLETE"]; then
        echo "Clean qmake files for COMPLETE version"
        make clean
        rm -rf qbTool Makefile .qmake.stash
    fi
    qmake

    echo "=== Cleaning old build ==="
    make clean

    echo "=== Building qbTool ==="
    make -j$(nproc)

    cd ..

    # Copy new binary to Appdir
    echo "=== Copying qbTool binary to Appdir ==="
    cp qbtool-gui-internal/qbTool Appdir/usr/bin/

    # Copy qt.conf (linuxdeployqt will regenerate, but ensure it's present)
    if [ -f /opt/qt515/bin/qt.conf ]; then
        cp /opt/qt515/bin/qt.conf Appdir/usr/bin/
    fi

    # Force-bundle libstdc++ and libgcc_s (same version used to compile Qt from beineri PPA)
    echo "=== Bundling required system libraries ==="
    LIB_SRC="/opt/qt515/lib"
    for lib in libstdc++.so.6 libgcc_s.so.1; do
        if [ -e "$LIB_SRC/$lib" ]; then
            cp -f "$LIB_SRC/$lib" Appdir/usr/lib/
            echo "  bundled $lib from $LIB_SRC"
        elif [ -e "/usr/lib/x86_64-linux-gnu/$lib" ]; then
            cp -f "/usr/lib/x86_64-linux-gnu/$lib" Appdir/usr/lib/
            echo "  bundled $lib from system"
        else
            echo "  WARNING: $lib not found!"
        fi
    done

    # Deploy AppImage
    echo "=== Running linuxdeployqt ==="
    rm -f qbTool-x86_64.AppImage
    ./linuxdeployqt-continuous-x86_64.AppImage \
        Appdir/usr/share/application/qbTool.desktop \
        -appimage \
        -verbose=2

    # Rename AppImage with variant tag
    if [ -f qbTool-x86_64.AppImage ]; then
        VARIANT_APPIMAGE="qbTool-${VARIANT}-x86_64.AppImage"
        mv qbTool-x86_64.AppImage "$VARIANT_APPIMAGE"
        echo ""
        echo "=== $VARIANT variant DONE ==="
        echo "AppImage: $(ls -lh $VARIANT_APPIMAGE)"
    else
        echo ""
        echo "ERROR: AppImage was NOT created for $VARIANT!"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "  All variants built successfully!"
echo "=========================================="
echo "Output files:"
ls -lh qbTool-*-x86_64.AppImage 2>/dev/null || echo "(none)"

echo "Cleaning Subrepo at last..."

cd qbtool-gui-internal
make clean
rm -rf qbTool Makefile .qmake.stash

