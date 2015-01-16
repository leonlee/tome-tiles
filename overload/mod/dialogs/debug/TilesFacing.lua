-- ToME - Tales of Maj'Eyal
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
	game.tiles_facing = game.tiles_facing or {}
	self:generateList()
	engine.ui.Dialog.init(self, "Tiles Facing", game.w, game.h)

	self.out = Textzone.new{width=800, auto_height=1, text=""}
	self.clist = List.new{scrollbar=true, width=400, height=self.ih - 5, list=self.list, fct=function(item) self:use(item) end}--, select=function(item) self:use(item) end}
	self.img = Image.new{auto_width=true, auto_height=true, zoom=4, file="invis.png"}
	self.reset = Button.new{text="Reset", fct=function() self:resetSpots() end}

	self:loadUI{
		{left=0, top=0, ui=self.clist},
		{left=420, top=0, ui=self.img},
		{right=0, top=10, ui=self.reset},
		{right=0, bottom=20, ui=self.out},
	}
	self:setupUI(false, false)

	game:setMouseCursor("/data/gfx/shockbolt/invis.png", nil, 16, 16)

	self.key:addBinds{
		MOVE_RIGHT = function() self:setSpot("right") end,
		MOVE_LEFT = function() self:setSpot("left") end,
		EXIT = function() game:unregisterDialog(self) end,
	}	
end

function _M:unload()
	game:defaultMouseCursor()

	local sets = {}
	for id, kind in pairs(game.tiles_facing) do
		if kind.flipx ~= nil then
			local _, _, dollrace, sex = id:find("dolls_(.*)_(.*)")
			local t
			if dollrace then
				local tileset, addon = self:getInfos(self.list[id])
				sets[tileset] = sets[tileset] or {}
				sets[tileset][addon] = sets[tileset][addon] or {}
				t = sets[tileset][addon]

				t[#t+1] = ('dolls.%s = dolls.%s or {}\n'):format(dollrace, dollrace)
				t[#t+1] = ('dolls.%s.%s = { flipx=%s }\n'):format(dollrace, sex, tostring(kind.flipx))
			else
				local tileset, addon = self:getInfos(id)
				sets[tileset] = sets[tileset] or {}
				sets[tileset][addon] = sets[tileset][addon] or {}
				t = sets[tileset][addon]

				t[#t+1] = ('tiles[%q] = { flipx=%s }\n'):format(id, tostring(kind.flipx))
			end
		end
	end

	for tileset, d in pairs(sets) do
		for addon, t in pairs(d) do
			print("****************** ", tileset, addon)
			print(table.concat(t))
			local path
			if addon == "main" then path = "game/modules/tome/data/gfx/"..tileset.."/facings.lua"
			elseif fs.exists("/addons/tome-"..addon) then path = "game/addons/tome-"..addon.."/overload/data/gfx/"..tileset.."/facings-"..addon..".lua"
			elseif fs.exists("/dlcs/tome-"..addon) then path = "game/dlcs/tome-"..addon.."/overload/data/gfx/"..tileset.."/facings-"..addon..".lua"
			end
			print("=>>", path)
			local f, err = io.open(path, "w")
			print(f, err)
			if addon == "main" then f:write('tiles={} dolls={}\n\n') end
			f:write(table.concat(t))
			f:close()
		end
	end
end

function _M:setSpot(kind)
	if not self.cur_item then return end
	local as = self.cur_item.kind
	game.tiles_facing[as] = game.tiles_facing[as] or {}

	game.tiles_facing[as].flipx = kind == "right"
	self:updateColorList(self.cur_item)
	self.clist:select(self.clist.sel+1)
	self.clist:onUse()
end

function _M:resetSpots()
	if not self.cur_item then return end
	local as = self.cur_item.kind
	game.tiles_facing[as] = nil
	self:updateColorList(self.cur_item)
end

function _M:hasSpots(as)
	if not game.tiles_facing[as] then return 0 end
	local kind = game.tiles_facing[as]
	if not kind then return 0 end
	if kind.flipx == true then return 1
	elseif kind.flipx == false then return 2
	else return 0 end
end

function _M:getInfos(name)
	local tileset = "shockbolt"
	local _, _, tilesetc = Tiles.prefix:find("/data/gfx/([^/]+)/")
	if tilesetc then tileset = tilesetc end
	local addon = "main"
	local path = fs.getRealPath(Tiles.prefix..name)
	local _, _, pathc = path:find("dlcs/tome%-([^/]+)/")
	if pathc then addon = pathc end
	local _, _, pathc = path:find("addons/tome%-([^/]+)/")
	if pathc then addon = pathc end

	return tileset, addon, name
end

function _M:use(item)
	if not item or not self.uis or not self.uis[2] then return end
	if self.cur_item == item then return end
	local old = self.img
	self.img = Image.new{auto_width=true, auto_height=true, zoom=4, file=item.name, back_color={0, 200, 120, 120}}
	self.uis[2].ui = self.img
	self.cur_item = item

	local tileset, addon, name = self:getInfos(item.name)

	self.out.text = tileset..":"..addon.."@"..name
	self.out:generate()
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
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_dwarf_male", name="player/dwarf_male/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_elf_female", name="player/elf_female/base_redhead_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_elf_male", name="player/elf_male/base_redhead_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_ghoul_all", name="player/ghoul/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_halfling_female", name="player/halfling_female/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_halfling_male", name="player/halfling_male/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_human_female", name="player/human_female/base_cornac_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_human_male", name="player/human_male/base_cornac_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_orc_all", name="player/orc/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_runic_golem_all", name="player/runic_golem/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_skeleton_all", name="player/skeleton/base_01.png"}
	list[list[#list].kind] = list[#list].name
	list[#list+1] = {kind="dolls_race_yeek_all", name="player/yeek/base_01.png"}
	list[list[#list].kind] = list[#list].name
	self:triggerHook{"TilesAttacher:list", list=list}

	for i, data in ipairs(list) do self:updateColorList(data) end

	table.sort(list, function(a,b) return a.kind < b.kind end)

	self.list = list
end

function _M:updateColorList(item)
	local cols = { [0] = colors.simple(colors.WHITE), [1] = colors.simple(colors.ORANGE), [2] = colors.simple(colors.LIGHT_GREEN) }
	local color = cols[self:hasSpots(item.kind)]
	item.color = color
	if self.clist then self.clist:drawItem(item) end
end
