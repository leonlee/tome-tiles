-- ToME - Tales of Maj'Eyal:
-- Copyright (C) 2009 - 2015 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local class = require"engine.class"

class:bindHook("DebugMain:use", function(self, data)
	if data.act == "tileattach" then
		package.loaded['mod.dialogs.debug.TilesAttacher'] = nil
		game:registerDialog(require("mod.dialogs.debug.TilesAttacher").new())
	end
	if data.act == "tilefacing" then
		package.loaded['mod.dialogs.debug.TilesFacing'] = nil
		game:registerDialog(require("mod.dialogs.debug.TilesFacing").new())
	end
end)

class:bindHook("DebugMain:generate", function(self, data)
	data.menu[#data.menu+1] = {name="Set tiles attachements", action="tileattach"}
	data.menu[#data.menu+1] = {name="Set tiles facing", action="tilefacing"}
end)
