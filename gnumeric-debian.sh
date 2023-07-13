#!/bin/sh

APP=gnumeric
 
mkdir tmp
cd tmp

# DOWNLOADING THE DEPENDENCIES
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$(uname -m).AppImage -O appimagetool
wget https://raw.githubusercontent.com/ivan-hc/AM-application-manager/main/tools/pkg2appimage
chmod a+x ./appimagetool ./pkg2appimage

# CREATING THE APPIMAGE: APPDIR FROM A RECIPE...
echo "app: gnumeric
binpatch: true

ingredients:
  dist: stable
  sources:
    - deb http://deb.debian.org/debian/ stable main contrib non-free
    - deb http://deb.debian.org/debian-security/ stable-security main contrib non-free
    - deb http://deb.debian.org/debian stable-updates main contrib non-free
    - deb http://deb.debian.org/debian stable-backports main contrib non-free
  packages:
    - gnumeric" >> recipe.yml

./pkg2appimage ./recipe.yml

# ...DOWNLOADING LIBUNIONPRELOAD...
wget https://github.com/project-portable/libunionpreload/releases/download/amd64/libunionpreload.so
chmod a+x libunionpreload.so
mv ./libunionpreload.so ./$APP/$APP.AppDir/

# ...REPLACING THE EXISTING APPRUN WITH A CUSTOM ONE...
rm -R -f ./$APP/$APP.AppDir/AppRun
cat > ./$APP/$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"
export LD_PRELOAD="${HERE}/libunionpreload.so"
export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"
export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
#export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}"/usr/share/pyshared/:"${PYTHONPATH}"
export PYTHONHOME="${HERE}"/usr/
export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"
export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}"/usr/lib/qt4/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib32/qt4/plugins/:"${HERE}"/usr/lib64/qt4/plugins/:"${HERE}"/usr/lib/qt5/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib32/qt5/plugins/:"${HERE}"/usr/lib64/qt5/plugins/:"${QT_PLUGIN_PATH}"
unset $GTK_PATH
export GTK_PATH="${HERE}"/usr/lib/x86_64-linux-gnu/gtk-2.0
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
exec ${EXEC} "$@" 2> /dev/null
EOF
chmod a+x ./$APP/$APP.AppDir/AppRun

# ...IMPORT THE LAUNCHER AND THE ICON TO THE APPDIR (uncomment if not available)...
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/22x22/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/24x24/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/32x32/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/48x48/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/64x64/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/128x128/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/256x256/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/512x512/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/scalable/apps/* ./$APP/$APP.AppDir/ 2>/dev/null
#cp ./$APP/$APP.AppDir/usr/share/applications/* ./$APP/$APP.AppDir/ 2>/dev/null

# ...EXPORT THE APPDIR TO AN APPIMAGE!
ARCH=x86_64 ./appimagetool -n ./$APP/$APP.AppDir
VERSION=$(echo $(wget -q https://packages.debian.org/stable/amd64/gnumeric/download -O - | grep "gnumeric_" | tail -1 | grep -o -P '(?<=gnumeric_).*(?=_amd64.deb)'))

cd ..
mv ./tmp/*.AppImage ./Gnumeric-$VERSION-x86_64.AppImage

#rm -R -f ./tmp