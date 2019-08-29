name = "Wormwood Legendary Edition"
author = "Majaw"
version = "1.0.0"
description = "Adds new functionality for Wormwood\nVersion: "..version
forumthread = ""

api_version = 10
dst_compatible = true
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
"character",
"interface"
}

configuration_options = {
-- --- Blooms Now --- --
	{
		name = "blooms_now",
		label = "Control the Blooms Stage",
		options =	{
						{description = "True", data = true},
						{description = "False", data = false}
					},

		default = true,
	},

-- --- Skin Blooms --- --
	{
		name = "skin_blooms",
		label = "Enable More Blooms for Skins",
		options =	{
						{description = "True", data = true},
						{description = "False", data = false}
					},

		default = true,
	},

-- --- Normal Source --- --
	{
		name = "normal_source",
		label = "Enable Normal Font for Phrases",
		options =	{
						{description = "True", data = true},
						{description = "False", data = false}
					},

		default = false,
	}
}