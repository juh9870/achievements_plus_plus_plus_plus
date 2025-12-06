local flib_locale = require("__flib__.locale")
local flib_prototypes = require("__flib__.prototypes")

---@class IconDef
---@field amount number
---@field bg string
---@field extra? string

---@type IconDef[]
local item_amounts = {
	{ amount = 1, bg = "bronze" },
	{ amount = 1000, bg = "silver" },
	{ amount = 1e6, bg = "gold" },
	-- { amount = 1e9, bg = "gold", extra="B" },
}

---@param amount integer
local function amount_str(amount)
	amountStr = tostring(amount)
	if amountStr:sub(-9) == "000000000" then
		return amountStr:sub(0, -10) .. "B"
	elseif amountStr:sub(-6) == "000000" then
		return amountStr:sub(0, -7) .. "M"
	elseif amountStr:sub(-3) == "000" then
		return amountStr:sub(0, -4) .. "k"
	else
		return amountStr
	end
end

---@type {[data.ItemID]: boolean}
local items_whitelist = {}
---@type {[data.FluidID]: boolean}
local fluids_whitelist = {}

for _, recipe in pairs(data.raw["recipe"]) do
	if not recipe.hidden then
		if recipe.results then
			for _, result in ipairs(recipe.results) do
				if result.type == "item" then
					items_whitelist[result.name] = true
				elseif result.type == "fluid" then
					fluids_whitelist[#fluids_whitelist + 1] = result.name
				end
			end
		end
	end
end

---@type data.AchievementPrototype[]
local achievements = {}

items_whitelist["electronic-circuit"] = false

for item, doIt in pairs(items_whitelist) do
	local name = "appp-craft-" .. item
	local itemData = flib_prototypes.find("item", item)  --[[@as data.ItemPrototype]]
	if not doIt then
		goto continue
	end
	if not itemData then
		log("Item `" .. item .. "` is not present despite being craftable")
		goto continue
	end

	---@type data.LocalisedString
	local itemName = flib_locale.of_item(itemData)
	for idx, info in ipairs(item_amounts) do
		local amount = info.amount
		---@type data.IconData[]
		local icons
		if itemData.icon then
			icons = {
				{
					icon = itemData.icon,
					icon_size = itemData.icon_size
				},
			}
		elseif itemData.icons then
			---@diagnostic disable-next-line: cast-local-type
			icons = table.deepcopy(itemData.icons)
		else
			icons = {}
		end
		for _, icon in ipairs(icons) do
			local icon_scale = 0.75
			if icon.icon_size and icon.icon_size > 64 then
				icon_scale = icon_scale * 64 / icon.icon_size
			end
			if icon.scale then
				icon.scale = icon.scale * icon_scale
			else
				icon.scale = icon_scale
			end
			if icon.shift then
				if icon.shift.x then
					icon.shift.x = icon.shift.x * icon_scale
				end
				if icon.shift.y then
					icon.shift.y = icon.shift.y * icon_scale
				end
				if icon.shift[0] then
					icon.shift[0] = icon.shift[0] * icon_scale
				end
				if icon.shift[1] then
					icon.shift[1] = icon.shift[1] * icon_scale
				end
			end
		end

		if info.extra then
		icons[#icons + 1] = {
			icon = "__base__/graphics/icons/signal/signal_" .. info.extra .. ".png",
			scale = 0.35,
			shift = { -14, 14 },
		}
		end
		table.insert(icons, 1, {
			icon = "__achievements_plus_plus_plus_plus__/graphics/achievement/bg_" .. info.bg .. ".png",
			icon_size = 128,
		})
		---@type data.ProduceAchievementPrototype
		local a = {
			type = "produce-achievement",
			name = name .. amount,
			localised_name = { "achievement-name.appp-item-name-template", tostring(idx), itemName },
			localised_description = {
				"achievement-description.appp-item-description-template",
				amount_str(amount),
				itemName,
			},
			item_product = item,
			amount = amount,
			limited_to_one_game = false,
			icons = icons,
		}
		achievements[#achievements + 1] = a
	end
	::continue::
end

data:extend(achievements)
