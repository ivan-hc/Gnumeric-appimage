#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=gnumeric
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES=""
#BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
VERSION=$(wget -q https://archlinux.org/packages/extra/x86_64/$APP/ -O - | grep $APP | head -1 | grep -o -P '(?<='$APP' ).*(?=</)' | tr -d " (x86_64)")

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir

# ENTER THE APPDIR
cd $APP.AppDir

# SET APPDIR AS A TEMPORARY $HOME DIRECTORY, THIS WILL DO ALL WORK INTO THE APPDIR
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
wget -q --show-progress https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz
./.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz
rm -f junest-x86_64.tar.gz

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# ENABLE CHAOTIC-AUR
###./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
###./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
###./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
###echo "
###[chaotic-aur]
###Include = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
#COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
#rm -R ./.junest/etc/pacman.d/mirrorlist
#wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# BYPASS SIGNATURE CHECK LEVEL
sed -i 's/#SigLevel/SigLevel/g' ./.junest/etc/pacman.conf
sed -i 's/Required DatabaseOptional/Never/g' ./.junest/etc/pacman.conf

# UPDATE ARCH LINUX IN JUNEST
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts $(echo "$BASICSTUFF $COMPILERS $DEPENDENCES $APP")

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
rm -R -f ./*.desktop
LAUNCHER=$(grep -iRl $BIN ./.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./
ICON=$(cat $LAUNCHER | grep "Icon=" | cut -c 6-)
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/pixmaps/*$ICON* ./ 2>/dev/null

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
rm -R -f ./AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$PATH:$HERE/.local/share/junest/bin
mkdir -p $HOME/.cache
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/lib/locale --bind=/etc --bind=/usr/share/fonts --bind=/usr/share/themes" 2> /dev/null -- $EXEC "$@"
EOF
chmod a+x ./AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh

# EXIT THE APPDIR
cd ..

# EXTRACT PACKAGE CONTENT
mkdir base
tar fx $APP.AppDir/.junest/var/cache/pacman/pkg/$APP*.zst -C ./base/

mkdir deps
for arg in $DEPENDENCES; do
	for var in $arg; do
 		tar fx $APP.AppDir/.junest/var/cache/pacman/pkg/$arg*.zst -C ./deps/
	done
done

# REMOVE SOME BLOATWARES
find ./$APP.AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find ./$APP.AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./$APP.AppDir/.junest/etc/makepkg.conf
rm -R -f ./$APP.AppDir/.junest/etc/pacman.conf
rm -R -f ./$APP.AppDir/.junest/usr/include #FILES RELATED TO THE COMPILER
rm -R -f ./$APP.AppDir/.junest/usr/man #APPIMAGES ARE NOT MENT TO HAVE MAN COMMAND
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# IN THE NEXT 4 STEPS WE WILL TRY TO LIGHTEN THE FINAL APPIMAGE PACKAGE
# WE WILL MOVE EXCESS CONTENT TO BACKUP FOLDERS (STEP 1)
# THE AFFECTED DIRECTORIES WILL BE /usr/bin (STEP 2), /usr/lib (STEP 3) AND /usr/share (STEP 4)

# STEP 1, CREATE A BACKUP FOLDER WHERE TO SAVE THE FILES TO BE DISCARDED (USEFUL FOR TESTING PURPOSES)
mkdir -p ./junest-backups/usr/bin
mkdir -p ./junest-backups/usr/lib/dri
mkdir -p ./junest-backups/usr/share

# STEP 2, FUNCTION TO SAVE THE BINARIES IN /usr/bin THAT ARE NEEDED TO MADE JUNEST WORK, PLUS THE MAIN BINARY/BINARIES OF THE APP
# IF YOU NEED TO SAVE MORE BINARIES, LIST THEM IN THE "BINSAVED" VARIABLE. COMMENT THE LINE "_savebins" IF YOU ARE NOT SURE.
_savebins(){
	BINSAVED="SAVEBINSPLEASE"
	mkdir save
	mv ./$APP.AppDir/.junest/usr/bin/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/bin/bash ./save/
	mv ./$APP.AppDir/.junest/usr/bin/env ./save/
	mv ./$APP.AppDir/.junest/usr/bin/proot* ./save/
	mv ./$APP.AppDir/.junest/usr/bin/sh ./save/
	for arg in $BINSAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/bin/*"$arg"* ./save/
		done
	done
	mv ./$APP.AppDir/.junest/usr/bin/* ./junest-backups/usr/bin/
	mv ./save/* ./$APP.AppDir/.junest/usr/bin/
 	rsync -av ./base/usr/bin/* ./$APP.AppDir/.junest/usr/bin/
	rmdir save
}
_savebins 2> /dev/null

# STEP 3, MOVE UNNECESSARY LIBRARIES TO A BACKUP FOLDER (FOR TESTING PURPOSES)
mkdir save

_binlibs(){
	readelf -d ./$APP.AppDir/.junest/usr/bin/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	mv ./$APP.AppDir/.junest/usr/lib/ld-linux-x86-64.so* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/*$APP* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/libdw* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/libelf* ./save/
	SHARESAVED="SAVESHAREPLEASE" # Enter here keywords or file/folder names to save in /usr/lib. By default, the names of the folders that you will save in /usr/share are selected also here.
	for arg in $SHARESAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/lib/*"$arg"* ./save/
		done
	done
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		for var in $arg; do
			mv ./$APP.AppDir/.junest/usr/lib/$arg* ./save/
			find ./$APP.AppDir/.junest/usr/lib/ -name $arg -exec cp -r --parents -t save/ {} +
		done 
	done
	rm -R -f $(find ./save/ | sort | grep ".AppDir" | head -1)
	rm list
}

_include_swrast_dri(){
	mkdir ./save/dri
	mv ./$APP.AppDir/.junest/usr/lib/dri/swrast_dri.so ./save/dri/
}

_libkeywords(){
	LIBSAVED="SAVELIBSPLEASE" # Enter here keywords or file/folder names to save in /usr/lib.
	for arg in $LIBSAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/lib/*"$arg"* ./save/
		done
	done
}

_liblibs(){
	readelf -d ./save/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
 	readelf -d ./base/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
  	readelf -d ./deps/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		for var in $arg; do
			mv ./$APP.AppDir/.junest/usr/lib/$arg* ./save/
			find ./$APP.AppDir/.junest/usr/lib/ -name $arg -exec cp -r --parents -t save/ {} +
		done 
	done
	rsync -av ./save/$APP.AppDir/.junest/usr/lib/* ./save/
 	rm -R -f $(find ./save/ | sort | grep ".AppDir" | head -1)
	rm list
}

_mvlibs(){
	mv ./$APP.AppDir/.junest/usr/lib/* ./junest-backups/usr/lib/
	mv ./save/* ./$APP.AppDir/.junest/usr/lib/
 	rsync -av ./base/usr/lib/* ./$APP.AppDir/.junest/usr/lib/
}

_binlibs 2> /dev/null

#_include_swrast_dri 2> /dev/null

#_libkeywords 2> /dev/null

_liblibs 2> /dev/null
_liblibs 2> /dev/null
_liblibs 2> /dev/null
_liblibs 2> /dev/null
_liblibs 2> /dev/null

_mvlibs 2> /dev/null

rmdir save

# STEP 4, SAVE ONLY SOME DIRECTORIES CONTAINED IN /usr/share
# IF YOU NEED TO SAVE MORE FOLDERS, LIST THEM IN THE "SHARESAVED" VARIABLE. COMMENT THE LINE "_saveshare" IF YOU ARE NOT SURE.
_saveshare(){
	SHARESAVED="SAVESHAREPLEASE"
	mkdir save
	mv ./$APP.AppDir/.junest/usr/share/*$APP* ./save/
 	mv ./$APP.AppDir/.junest/usr/share/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/share/fontconfig ./save/
	mv ./$APP.AppDir/.junest/usr/share/glib-* ./save/
	mv ./$APP.AppDir/.junest/usr/share/locale ./save/
	mv ./$APP.AppDir/.junest/usr/share/mime ./save/
	mv ./$APP.AppDir/.junest/usr/share/wayland ./save/
	mv ./$APP.AppDir/.junest/usr/share/X11 ./save/
	for arg in $SHARESAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/share/*"$arg"* ./save/
		done
	done
	mv ./$APP.AppDir/.junest/usr/share/* ./junest-backups/usr/share/
	mv ./save/* ./$APP.AppDir/.junest/usr/share/
 	rsync -av ./base/usr/share/* ./$APP.AppDir/.junest/usr/share/
	rmdir save
}
_saveshare 2> /dev/null

# ADDITIONAL REMOVALS
mv ./$APP.AppDir/.junest/usr/lib/libLLVM-* ./junest-backups/usr/lib/ #INCLUDED IN THE COMPILATION PHASE, CAN SOMETIMES BE EXCLUDED FOR DAILY USE
rm -R -f ./$APP.AppDir/.junest/usr/lib/python*/__pycache__/* #IF PYTHON IS INSTALLED, REMOVING THIS DIRECTORY CAN SAVE SEVERAL MEGABYTES

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./Gnumeric-Spreadsheet_$VERSION-archimage2.1-4-x86_64.AppImage
