Pick and place tool for minetest

![luacheck](https://github.com/BuckarooBanzay/pick_and_place/workflows/luacheck/badge.svg)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ContentDB](https://content.minetest.net/packages/BuckarooBanzay/pick_and_place/shields/downloads/)](https://content.minetest.net/packages/BuckarooBanzay/pick_and_place/)

# Features

* Select and place areas on the fly
* Configure an area with "handles" to pick and place them quickly
* Rotation around the y-axis

# Screenshots

![Placement tool](./screenshot_place.png)

![Pickup handles](./screenshot_configure.png)

# Howto

## Quick pick-and-place

Simple copy+paste operation

* Use the green `pick_and_place:pick` tool to select the area to use
* First click for first position and second click for the second position
* This will convert the pick-tool to a blue `pick_and_place:place` tool in your inventory
* Use the place-tool to place your build anywhere in the world with the help of the preview-overlay
* The schematic can be rotated around the y-axis with the menu that pops up on right-click

**Pro-tip**: hold the `aux` key to switch to removal-mode

## Configure a template area

Create a template for frequent reuse

* Use the white `pick_and_place:configure` tool to select an area for your template
* First click for first position and second click for the second position
* This will create "handle" nodes on every corner of the build
* Right-click one of corners to create a placement-tool for the template
* Place as needed

## Replacements

The `pick_and_place:replacement` node can be used to randomize node placement.

If you pick-and-place a replacement node the default node-placement is replaced with the configured inventory- and group-configuration.

* Inventory: Upon placement a random slot of the replacement inventory is selected and placed instead of the node
* The `param2` value is preserved and rotateable
* A "group" can be specified to place the same randomized slot across the whole group and placement

**Note**: holding the "zoom" button on place disables the replacement engine

# Portability

The placement tool can be shared across worlds if the nodes are available there.

# Limitations

The schematic data is stored in the tool and may not scale well beyond a certain size

# Licenses

* Code: `MIT`
* Media: `CC-BY-SA 3.0`
