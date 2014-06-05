iTrajComp
=====

The **iTrajComp** VMD plugin is a general analysis tool for trajectories.

It is under heavy development, but it can already do a few interesting things (no guarantees, though!). In hopes of helping our fellow VMD users, this webpage will host the preview releases of the tool. If you are interested in trying this tool, please contact the author. Once we are confident that the plugin is doing what it should and we get some time to write a little manual, it will be freely available from this webpage.

> Website: http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

## Installation

A small guide on how to install third party VMD plugins can be found [here](http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/installation.html). In summary:

1. Create a VMD plugins' directory if you don't have one, ie */path/to/plugins/directory*.
2. Clone or download the project into a subdirectory of your *VMD plugins' directory* (ie. */path/to/plugins/directory/itrajcomp*):
```sh
cd /path/to/plugins/directory
git clone https://github.com/luisico/itrajcomp.git itrajcomp
```
3. Add the following to your *$HOME/.vmdrc* file (if you followed the instructions in the link above, you might already have the first line present):
```tcl
set auto_path [linsert $auto_path 0 {/path/to/plugins/directory}]
vmd_install_extension itrajcomp itrajcomp_tk_cb "WMC PhysBio/iTrajComp"
```
The iTrajComp plugin should be accessible from the Extensions menu.

### Speeding up rmsd calculations in VMD

Due to the repetition of the calculations, these can take a long time. I have created a patch for VMD's `measure rmsd` command that adds two options to speed up by residue and by atoms rmsd calculations, while maintaining compatibility with the standard command. New options are:
  - *byres*: will return an array with all the rmsd by residue in the selection after the global rmsd.
  - *byatom*: will return an array with all the rmsd by atom in the selection after the global rmsd.

A patch for VMD can be found in [RMSDTT](https://github.com/luisico/rmsdtt/tree/master/patches). You will need to recompile VMD. iTrajComp will use it if available.

Example use:
```tcl
lassign [measure rmsd $sel1 $sel2 byres] rmsd_global rmsd_byres

```
## Getting started

1. Load a small trajectory in vmd. Clculations on large trajectories might take a while, I recommend to use a small one while learning your way around the iTrajcomp

2. Click on tab `Selection` (upper right) and do your selection:
   - Atom selection: enter **all** in the text field
   - Molecules: **Top** (your current top molecule in the main window 'T')
   - Frames: **All**
   - Modifiers: **Trace** (behind the scenes this will transform the selection into "all and name CA")
   - Activate **Same selection**

3. Click on tab `Calculation` (upper right)
   a.  Select **rmsd**
   b.  Select **align** from the options. This will pre-align the pair of frames before calculating the rmsd

4. Click on **Calculate** (upper center) and you will get a new window. It might take some time if you trajectory is large

5. In the new window you see 3 tabs (Graph, Representations, Info). In the initial tab **Graph** you see a diagonal matrix, a color scale, a zoom interface, the calculation type options (*Set*) and some matrix manipulation options (*Keys*, *keep*,...):
   - Move your **mouse** around the matrix. You will see the correspoding key and value (rmsd in this case) in the lower left. Each key is (mol frame).
   - **Click** on a matrix cell. The color will change and the 2 structures (key1, key2) will be shown in VMD' graphic window. Their representation can be changed if you click in the tab **Representations** (this tab should be easy to understand)
     - Look in men *Help | Keybindings* for other options to select/deselect cells.
     - Option *keep* allows you to fix *Keys/Value*. They won't update while moving the mouse) but will change if you select/deselect a cell.
     - Options *Add/Del* help in adding/deleting cells when using batch selection (see *Help | Keybindings*)
   - Change the size of the cells with the **zoom** buttons
   - The color **scale**, well, gives an idea of the range of values. See *Help | Keybindings* for batch selection based on values
   - The menu **Transform** changes the values of each cell based on the selected function. You can always use the *Reset* option in that menu to get back to the original data. If the *Source is raw data* is active the source values for the transformation are the original data, otherwise the source values are the current ones displayed, ie. you could inverse and then normalize.
   - Data can be view and saved in different formats with the **File** menu. Use the matrix format to import it later in R.

## Reference

### Supported calculations

iTrajComp supports two calculation modes, *frames* and *segments*.

#### Frames mode

Each cell in the graph represents a pair of molecule/frame. For exapmle, cell `(0 1) (3 5)` in a rmsd graph contains the rmsd between `(molecule 0, frame 1)` and `(molecule 3, frame5)`.

In this mode the number of cells in the graph will depend on the number of molecules and frames, and is independent of the number of atoms. For example, a *rmsd* calculation with 2 molecules, each with 20 frames, 25 residues and 100 atoms will results in a graph of 40 by 40 cells.

Calculation types:
* **contacts**: number of contacts within a cutoff
* **hbonds**: number of hydrogen bonds within a cutoff, angle (as defined in VMD)
* **labels**: bonds, angles, dihedrals
* **rgyr**: radius of gyration
* **rmsd**: rmsd

#### Segments mode

In segments mode calculations are based on molecule segments, ie, residues or atoms. Each cell in the graph represents a pair of segments. For example, cell `(5 Glu) (7 Arg)` in a dist by residue graph contains the distance between residues `5 (Glu)` and `7 (Arg)`.

In this mode the number of cells in the graph will depend on the number of segments (atoms or residues) and is independent of the number of molecules or frames. For example, a *dist* calculation with 2 molecules, each with 20 frames, 25 residues and 100 atoms will results in a graph of 25 by 25 cells if the segments are residues and 100 by 100 if the segments are atoms.

Calculation types:
* **covar**: covariance among segments
* **dist**: distance among segments

#### Custom calculations

iTrajComp supports custom calculations created by users. Stay tunned for more information on how to created your own iTrajComp driven calculations.

### GUI

In the **main window** you find:

* **Menu**:
  * **File**: Load previously save results (*objects*).
  * **Options**: Activate/deactivate the progress bar.
  * **Combine**: Combine *objects*, ie `($1 + $2) / 2` will calculate the mean between to *object* results for each corresponding cell.

* 3 main **Tabs**:
  * **Selection**: make selections in this tab. It support 1 or 2 sets of atoms.
  * **Calculation**: select calculation type and options. Start a calculation with the *Calculate* button.
  * **Results**: index of calculation (*objects*) run so far.

**Each run** will create a new window (*object*) with a new GUI to show the results:
* **Menu**:
  * **File**: save results in different formats, view the raw data, hide the object (stil available from *Results* tab in the main plugin window) and destroy the object.
  * **Transform**: modify the data represented in the graph using different functions (inverse, normalize). Reset graph to the raw data. *source is raw data* selects the raw data as the source of the transformation. Otherwise the current data in the graph is used.
  * **Analysis**: calculate a few statistical descriptors on the current displayed data.

* **Tabs**:
  * **Graph**: 3D representation of the results. X/Y axis hold the *molecule/frame* or *residue/atom* pair depending on the type of calculation. Z is represented by the color of the cell. Click on the cells to see/hide representations in VMD's graphics window (see also *Help / Keybinding*).
    * **Scale**: clicking in the scale will select cells (see also *Help / Keybinding*).
    * **Zoom**: self explained.
    * **Set**: select the set to use: depending on the type of calculation you'll get different options here.
    * **Keys/Value**: *molecule/frame* or *residue/atom* corresponding to the cell were the mouse points in the graph. Value for that pair. The *keep* option allow to move in the graph without changing *keys* and *value*.
    * **Options add/del**: finner control in the selection of cells to represent in the vmd graphics window.
    * **Clear**: delete all selections from the graph.
  * **Info**: information on the run
  * **Representation**: change the representation to use in VMD's graphics window when selecting cells.

You can create as many of this *Objects* as you want, using different atom selections, calculation types/options,... And even combine them with the **Combine** menu.

### Keybindings

The following keybindings are available in the graph and scale (when noted):

Key | Selection | Scale
:----|:-----|:
 B1       | Select/Deselect one cell |
 B2       | Explore data for cell |
 Shift-B1 | Selects all cells in column/row of data
 Shift-B2 | Selects all cells in column/row with values <= than data clicked | [x]
 Shift-B3 | Selects all cells in column/row with values => than data clicked | [x]
 Ctrl-B1  | Selects all cells |
 Ctrl-B2  | Selects all cells with values <= than data clicked | [x]
 Ctrl-B3  | Selects all cells with values => than data clicked | [x]

## Author

Luis Gracia (https://github.com/luisico)

Developed at Weill Cornell Medical College

## Contributors

Please, use issues and pull requests for feedback and contributions to this project.

## License

See LICENSE.
