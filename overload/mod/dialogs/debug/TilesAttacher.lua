-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012, 2013 Nicolas Casalini
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

require "engine.class"
require "engine.ui.Dialog"
local Tiles = require "engine.Tiles"
local List = require "engine.ui.List"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local ListColumns = require "engine.ui.ListColumns"
local Image = require "engine.ui.Image"
local GetQuantity = require "engine.dialogs.GetQuantity"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init()
	self:generateList()
	engine.ui.Dialog.init(self, "Tiles Attacher", game.w, game.h)

	self.t1 = Textzone.new{auto_width=1, auto_height=1, text="Head"}
	self.t2 = Textzone.new{auto_width=1, auto_height=1, text="Hand1"}
	self.t3 = Textzone.new{auto_width=1, auto_height=1, text="Hand2"}
	self.t4 = Textzone.new{auto_width=1, auto_height=1, text="Back"}
	self.t5 = Textzone.new{auto_width=1, auto_height=1, text="Belly"}
	self.t6 = Textzone.new{auto_width=1, auto_height=1, text="Feet"}

	self.mcoords = Textzone.new{width=100, auto_height=1, text=""}
	self.clist = List.new{scrollbar=true, width=400, height=self.ih - 5, list=self.list, fct=function(item) self:use(item) end}--, select=function(item) self:use(item) end}
	self.coords = ListColumns.new{width=300, height=self.ih - 5, list={}, fct=function(item) self:useCoords(item) end, select=function(item) self:useCoords(item) end, columns={
		{name="", width=10, display_prop="key"},
		{name="Spot", width=30, display_prop="name"},
		{name="X", width=30, display_prop=function(item) return item.x and tostring(item.x*self.img.iw) or "--" end},
		{name="Y", width=30, display_prop=function(item) return item.y and tostring(item.y*self.img.iw) or "--" end},
	}}
	self.img = Image.new{auto_width=true, auto_height=true, zoom=4, file="invis.png"}
	self.reset = Button.new{text="Reset", fct=function() self:resetSpots() end}

	self:loadUI{
		{left=0, top=0, ui=self.clist},
		{left=420, top=self.mcoords.h, ui=self.img},
		{left=420, top=0, ui=self.mcoords},
		{right=0, top=10 + self.reset.h, ui=self.coords},
		{right=0, top=10, ui=self.reset},
	}
	self:setupUI(false, false)

	game:setMouseCursor("/data/gfx/shockbolt/invis.png", nil, 16, 16)

	self.key:addBinds{
		HOTKEY_1 = function() self:setSpot("head") end,
		HOTKEY_2 = function() self:setSpot("hand1") end,
		HOTKEY_3 = function() self:setSpot("hand2") end,
		HOTKEY_4 = function() self:setSpot("back") end,
		HOTKEY_5 = function() self:setSpot("belly") end,
		HOTKEY_6 = function() self:setSpot("feet") end,
		EXIT = function() game:unregisterDialog(self) end,
	}	

	self.mouse:registerZone(420, self.mcoords.h, 150 * 4, 150 * 4, function(button, x, y, xrel, yrel, bx, by, event)
		local x, y = core.mouse.get()
		x, y = x - self.uis[2].x - self.display_x, y - self.uis[2].y - self.display_y
		x, y = math.floor(x / 4), math.floor(y / 4)
		self.mcoords.text = x.."x"..y
		self.mcoords:generate()

		if event == "button" and button == "left" then
			for _, d in ipairs(self.coords.list) do	if not d.x then self:setSpot(d.kind) break end end
		elseif event == "button" then
			for i = #self.coords.list,1,-1 do local d=self.coords.list[i] if d.x then self:resetSpots(d.kind) break end end
		end
	end)
end

function _M:unload()
	game:defaultMouseCursor()

	local t = { 'tiles={} dolls={}\n\n' }
	for id, data in pairs(game.tiles_attachements) do
		local ok = false
		for kind, d in pairs(data) do if kind ~= "base" and d.x then ok = true break end end
		if ok then
			local base = data.base or 64
			local _, _, dollrace, sex = id:find("dolls_(.*)_(.*)")
			if dollrace then
				t[#t+1] = ('dolls.%s = dolls.%s or {}\n'):format(dollrace, dollrace)
				t[#t+1] = ('dolls.%s.%s = { base=%d,\n'):format(dollrace, sex, base)
			else
				t[#t+1] = ('tiles[%q] = { base=%d,\n'):format(id, base)
			end

			for kind, d in pairs(data) do if kind ~= "base" and d.x then
				t[#t+1] = ('\t%s = {x=%d, y=%d},\n'):format(kind, d.x * base, d.y * base)
			end end
			t[#t+1] = '}\n'
		end
	end
	print(table.concat(t))
	print("=>>", "game/modules/tome/"..Tiles.prefix.."/attachements.lua")
	local f = io.open("game/modules/tome/"..Tiles.prefix.."/attachements.lua", "w")
	f:write(table.concat(t))
	f:close()
end

function _M:setSpot(kind)
	if not self.cur_item then return end
	local as = self.cur_item.kind
	game.tiles_attachements[as] = game.tiles_attachements[as] or {}
	game.tiles_attachements[as][kind] = game.tiles_attachements[as][kind] or {}

	local x, y = core.mouse.get()
	x, y = x - self.uis[2].x - self.display_x, y - self.uis[2].y - self.display_y
	x, y = math.floor(x / 4), math.floor(y / 4)

	if self.img.iw < self.img.ih then y = y - self.img.iw end

	game.tiles_attachements[as][kind].x, game.tiles_attachements[as][kind].y = x / self.img.iw, y / self.img.iw
	game.tiles_attachements[as].base = self.img.iw
	self.coords:setList(self:loadSpots(as), true)
	self:updateColorList(self.cur_item)
end

function _M:resetSpots(kind)
	if not self.cur_item then return end
	local as = self.cur_item.kind
	if not kind then
		game.tiles_attachements[as] = nil
	else
		game.tiles_attachements[as] = game.tiles_attachements[as] or {}
		game.tiles_attachements[as][kind] = {}
	end
	self.coords:setList(self:loadSpots(as), true)
	self:updateColorList(self.cur_item)
end

function _M:hasSpots(as)
	if not game.tiles_attachements[as] then return 0 end
	local list = game.tiles_attachements[as]
	local nb = 0
	for kind, d in pairs(list) do if kind ~= "base" and d.x then nb = nb + 1 end end
	if nb == 6 then return 2
	elseif nb == 0 then return 0
	else return 1 end
end

function _M:loadSpots(as)
	local list = game.tiles_attachements[as] or {}
	local get = function(k, x) if list[k] then return list[k][x] or nil else return nil end end
	local spots = {
		{key="1", name="Head", kind="head", x=get("head", "x"), y=get("head", "y")},
		{key="2", name="Hand1", kind="hand1", x=get("hand1", "x"), y=get("hand1", "y")},
		{key="3", name="Hand2", kind="hand2", x=get("hand2", "x"), y=get("hand2", "y")},
		{key="4", name="Back", kind="back", x=get("back", "x"), y=get("back", "y")},
		{key="5", name="Belly", kind="belly", x=get("belly", "x"), y=get("belly", "y")},
		{key="6", name="Feet", kind="feet", x=get("feet", "x"), y=get("feet", "y")},
	}

	return spots
end

function _M:useCoords(item)
	if not item or not self.uis or not self.uis[4] then return end
end

function _M:use(item)
	if not item or not self.uis or not self.uis[2] then return end
	if self.cur_item == item then return end
	local old = self.img
	self.img = Image.new{auto_width=true, auto_height=true, zoom=4, file=item.name, back_color={0, 200, 120, 120}}
	self.uis[2].ui = self.img
	self.coords:setList(self:loadSpots(item.kind), true)
	self.cur_item = item
end

function _M:generateList()
	local list = {}

	for i, file in ipairs(fs.list(Tiles.prefix.."npc")) do
		if file:find(".png$") then list[#list+1] = {kind="npc/"..file, name="npc/"..file} end
	end
	for i, file in ipairs(fs.list(Tiles.prefix.."player")) do
		if file:find(".png$") then list[#list+1] = {kind="player/"..file, name="player/"..file} end
	end
	list[#list+1] = {kind="dolls_race_dwarf_female", name="player/dwarf_female/base_01.png"}
	list[#list+1] = {kind="dolls_race_dwarf_male", name="player/dwarf_male/base_01.png"}
	list[#list+1] = {kind="dolls_race_elf_female", name="player/elf_female/base_redhead_01.png"}
	list[#list+1] = {kind="dolls_race_elf_male", name="player/elf_male/base_redhead_01.png"}
	list[#list+1] = {kind="dolls_race_ghoul_all", name="player/ghoul/base_01.png"}
	list[#list+1] = {kind="dolls_race_halfling_female", name="player/halfling_female/base_01.png"}
	list[#list+1] = {kind="dolls_race_halfling_male", name="player/halfling_male/base_01.png"}
	list[#list+1] = {kind="dolls_race_human_female", name="player/human_female/base_cornac_01.png"}
	list[#list+1] = {kind="dolls_race_human_male", name="player/human_male/base_cornac_01.png"}
	list[#list+1] = {kind="dolls_race_orc_all", name="player/orc/base_01.png"}
	list[#list+1] = {kind="dolls_race_runic_golem_all", name="player/runic_golem/base_01.png"}
	list[#list+1] = {kind="dolls_race_skeleton_all", name="player/skeleton/base_01.png"}
	list[#list+1] = {kind="dolls_race_yeek_all", name="player/yeek/base_01.png"}

	for i, data in pairs(list) do self:updateColorList(data) end

	table.sort(list, function(a,b) return a.kind < b.kind end)

	self.list = list
end

function _M:updateColorList(item)
	local cols = { [0] = colors.simple(colors.WHITE), [1] = colors.simple(colors.ORANGE), [2] = colors.simple(colors.LIGHT_GREEN) }
	local color = cols[self:hasSpots(item.kind)]
	item.color = color
	if self.clist then self.clist:drawItem(item) end
end

function _M:innerDisplay(bx, by, nb_keyframes)
	if not self.uis[2] then return end
	local x, y = core.mouse.get()
	x, y = x - self.uis[2].x - self.display_x, y - self.uis[2].y - self.display_y
	x, y = math.floor(x / 4) * 4, math.floor(y / 4) * 4

	core.display.drawQuad(bx + self.uis[2].x + x, by + self.uis[2].y + y, 4, 4, 255, 120, 0, 255)

	for kind, d in pairs(self.coords.list) do if d.x and d.y then
		local x, y = d.x * self.img.iw * 4, d.y * self.img.iw * 4
		x, y = bx + self.uis[2].x + x, by + self.uis[2].y + y

		if self.img.iw < self.img.ih then y = y + self.img.iw * 4 end

		core.display.drawQuad(x, y, 4, 4, 255, 0, 255, 255)
		y = y + 6

		self["t"..d.key]:display(x, y, nb_keyframes)
	end end
end
