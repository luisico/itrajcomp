#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=rmsdtt2
dir=$plugin
tar=$plugin-v$version.tgz

cd ../

tar zcvf $tar $dir/pkgIndex.tcl $dir/contacts.tcl $dir/gui.tcl $dir/hbonds.tcl $dir/labels.tcl $dir/maingui.tcl $dir/rms.tcl $dir/rmsdtt.tcl $dir/save.tcl $dir/utils.tcl $dir/README.txt


mv $tar $dir/versions
chmod go+rX $dir/versions/$tar
cd $dir

