#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=itrajcomp
dir=$plugin
tar=$plugin-v$version.tgz
files=( pkgIndex.tcl README.txt maingui.tcl buttonbar.tcl utils.tcl object.tcl save.tcl load.tcl combine.tcl gui.tcl standard.tcl user.tcl frames.tcl segments.tcl rmsd.tcl covar.tcl dist.tcl contacts.tcl hbonds.tcl labels.tcl rgyr.tcl )

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
chmod go+rX $dir/versions/$tar
cd $dir

