#!/bin/sh

version=$1
echo "Packing version ${version:?}"

cd ../

tar cvf rmsdtt2-v$version.tar rmsdtt2/pkgIndex.tcl rmsdta2t/contacts.tcl rmsdtt2/gui.tcl rmsdtt2/hbonds.tcl rmsdtt2/labels.tcl rmsdtt2/maingui.tcl rmsdtt2/rms.tcl rmsdtt2/rmsdtt.tcl rmsdtt2/save.tcl rmsdtt2/utils.tcl rmsdtt2/README.txt 

mv rmsdtt2-v$version.tar rmsdtt2/versions
cd rmsdtt2
