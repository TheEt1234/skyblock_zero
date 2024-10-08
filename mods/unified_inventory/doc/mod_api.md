unified_inventory API
=====================

This file provides information about the API of unified_inventory
and can be viewed in Markdown readers.

API revisions within unified_inventory can be checked using:

	(unified_inventory.version or 1)

**Revision history**

* Version `1`: Classic formspec layout (no real_coordinates)
* Version `2`: Force formspec version 4 (includes real_coordinates)

Misc functions
--------------
Grouped by use-case, afterwards sorted alphabetically.

* `unified_inventory.is_creative(name)`
	* Checks whether creative is enabled or the player has `creative`


Callbacks
---------

Register a callback that will be run whenever a craft is registered via unified_inventory.register_craft.
This callback is run before any recipe ingredients checks, hence it is also executed on recipes that are
purged after all mods finished loading.

	unified_inventory.register_on_craft_registered(
		function (item_name, options)
			-- item_name (string): name of the output item, equivalent to `ItemStack:get_name()`
			-- options (table): definition table of crafts registered by `unified_inventory.register_craft`
		end
	)

Register a callback that will be run after all mods have loaded and after the unified_inventory mod has initialised all its internal structures:

	unified_inventory.register_on_initialized(callback)
		-- The callback is passed no arguments


Accessing Data
--------------

These methods should be used instead of accessing the unified_inventory data structures directly - this will ensure your code survives any potential restructuring of the mod.

Get a list of recipes for a particular output item:

	unified_inventory.get_recipe_list(output_item)

	Returns a list of tables, each holding a recipe definition, like:
	{
		{
			type = "normal",
			items = { "default:stick", "default:stick", "default:stick", "default:stick" },
			output = "default:wood",
			width = 2
		},
		{
			type = "shapeless",
			items = { "default:tree" },
			output = "default:wood 4",
			width = 0
		},
		...
	}

Get a list of all the output items crafts have been registered for:

	unified_inventory.get_registered_outputs()

	Returns a list of item names, like:
	{
		"default:stone",
		"default:chest",
		"default:brick",
		"doors:door_wood",
		...
	}

oh yea i forgot to mention:

	unified_inventory.get_usage_list(item) - added by me, frog, its like get_recipe_list but gives you the usages instead... really unsure why this wasn't put in



Pages
-----

Register a new page: The callback inside this function is called on user input.

	unified_inventory.register_page("pagename", {
		get_formspec = function(player)
			-- ^ `player` is an `ObjectRef`
			-- Compute the formspec string here
			return {
				formspec = "button[2,2;2,1;mybutton;Press me]",
				-- ^ Final form of the formspec to display
				draw_inventory = false,   -- default `true`
				-- ^ Optional. Hides the player's `main` inventory list
				draw_item_list = false,   -- default `true`
				-- ^ Optional. Hides the item list on the right side
				formspec_prepend = false, -- default `false`
				-- ^ Optional. When `false`: Disables the formspec prepend
			}
		end,
	})


Buttons
-------

Register a new button for the bottom row:

	unified_inventory.register_button("skins", {
		type = "image",
		image = "skins_skin_button.png",
		tooltip = "Skins",
		hide_lite = true
		-- ^ Button is hidden when following two conditions are met:
		--   Configuration line `unified_inventory_lite = true`
		--   Player does not have the privilege `ui_full`
	})



Crafting
--------

The code blocks below document each possible parameter using exemplary values.

Provide information to display custom craft types:

	unified_inventory.register_craft_type("mytype", {
		-- ^ Unique identifier for `register_craft`
		description = "Sample Craft",
		-- ^ Text shown below the crafting arrow
		icon = "dummy.png",
		-- ^ Image shown above the crafting arrow
		width = 3,
		height = 3,
		-- ^ Maximal input dimensions of the recipes
		dynamic_display_size = function(craft)
			-- ^ `craft` is the definition from `register_craft`
			return {
				width = 2,
				height = 3
			}
		end,
		-- ^ Optional callback to change the displayed recipe size
		uses_crafting_grid = true,
	})

Register a non-standard craft recipe:

	unified_inventory.register_craft({
		output = "default:foobar",
		type = "mytype",
		-- ^ Standard craft type or custom (see `register_craft_type`)
		items = {
			{ "default:foo" },
			{ "default:bar" }
		},
		width = 3,
		-- ^ Same as `minetest.register_recipe`
	})


Categories
----------

 * `unified_inventory.register_category(name, def)`
     * Registers a new category
     * `name` (string): internal category name
     * `def` (optional, table): also its fields are optional

	unified_inventory.register_category("category_name", {
		symbol = source,
		-- ^ Can be in the format "mod_name:item_name" or "texture.png",
		label = "Human Readable Label",
		index = 5,
		-- ^ Categories are sorted by index. Lower numbers appear before higher ones.
		--   By default, the name is translated to a number: AA -> 0.0101, ZZ -> 0.2626
		---  Predefined category indices: "all" = -2, "uncategorized" = -1
		items = {
			"mod_name:item_name",
			"another_mod:different_item"
		}
		-- ^ List of items within this category
	})
 * `unified_inventory.remove_category(name)`
     * Removes an entire category

Modifier functions (to be removed)

 * `unified_inventory.set_category_symbol(name, source)`
     * Changes the symbol of the category. The category does not need to exist yet.
     * `name` (string): internal category name
     * `source` (string, optional): `"mod_name:item_name"` or `"texture.png"`.
       Defaults to `"default:stick"` if not specified.
 * `unified_inventory.set_category_label(name, label)`
     * Changes the human readable label of the category.
     * `name` (string): internal category name
     * `label` (string): human readable label. Defaults to the category name.
 * `unified_inventory.set_category_index(name, index)`
     * Changes the sorting index of the category.
     * `name` (string): internal category name
     * `index` (numeric): any real number

Item management

 * `	unified_inventory.add_category_item(name, itemname)`
     * Adds a single item to the category
     * `itemname` (string): self-explanatory
 * `unified_inventory.add_category_items(name, { itemname1, itemname2, ... }`
     * Same as above but with multiple items
 * `unified_inventory.remove_category_item(name, itemname)`
     * Removes an item from the category
 * `unified_inventory.find_category(itemname)`
     * Looks up the first category containing this item
     * Returns: category name (string) or nil
 * `unified_inventory.find_categories(itemname)`
     * Looks up the item name within all registered categories
     * Returns: array of category names (table)

