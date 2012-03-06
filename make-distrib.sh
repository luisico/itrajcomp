#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=itrajcomp
dir=$plugin
tar=$plugin-v$version.tgz
files=(
#clustering.tcl
README.txt
balloons.tcl
buttonbar.tcl
combine.tcl
contacts.tcl
covar.tcl
dist.tcl
frames.tcl
graphics.tcl
gui.tcl
hbonds.tcl
itrajcomp.tcl
labels.tcl
load.tcl
maingui.tcl
object.tcl
pkgIndex.tcl
rgyr.tcl
rmsd.tcl
save.tcl
segments.tcl
standard.tcl
user.tcl
utils.tcl
hacks.tcl
)

for f in ${files[@]}; do
    if [ ! -r $f ]; then
	echo "ERROR: File \"$dir/$f\" is not readable!"
	exit 11
    fi
    dirfiles="$dirfiles $dir/$f"
done

cd ../
tar zcvf $tar $dirfiles
mv $tar $dir/versions
chmod 644 $dir/versions/$tar
cd $dir



# docs
#robodoc --src ./ --doc ./docs --multidoc --nodesc --sections --documenttitle iTrajComp --index --html
