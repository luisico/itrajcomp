#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=itrajcomp
dir=$plugin
tar=$plugin-v$version.tgz

cd ../

tar zcvf $tar $dir/pkgIndex.tcl $dir/contacts.tcl $dir/gui.tcl $dir/hbonds.tcl $dir/labels.tcl $dir/maingui.tcl $dir/rmsd.tcl $dir/object.tcl $dir/save.tcl $dir/utils.tcl $dir/README.txt


mv $tar $dir/versions
chmod go+rX $dir/versions/$tar
cd $dir

