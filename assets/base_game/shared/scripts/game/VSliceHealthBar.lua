local barX = 350
local barY = 695
local barW = 580
local barH = 14
local frame = 4
local minFill = 1

local created = false
local tags = {
	'vSliceHealthShadow',
	'vSliceHealthFrame',
	'vSliceHealthBack',
	'vSliceHealthDad',
	'vSliceHealthBf',
	'vSliceHealthDivider'
}

function SliceHub()
	return sliceHub ~= false and hideHud ~= true
end

local function clamp(value, min, max)
	if value < min then return min end
	if value > max then return max end
	return value
end

local function makeHudBox(tag, x, y, w, h, color, front)
	makeLuaSprite(tag, nil, x, y)
	makeGraphic(tag, 1, 1, color)
	scaleObject(tag, w, h)
	setObjectCamera(tag, 'hud')
	addLuaSprite(tag, front)
end

function onCreatePost()
	if not SliceHub() then return end

	if downscroll then
		barY = 18
	end

	setProperty('healthBar.alpha', 0)
	if getProperty('healthBarBG') ~= nil then
		setProperty('healthBarBG.alpha', 0)
	end

	makeHudBox('vSliceHealthShadow', barX - frame - 2, barY - frame + 2, barW + frame * 2 + 4, barH + frame * 2, '000000', true)
	makeHudBox('vSliceHealthFrame', barX - frame, barY - frame, barW + frame * 2, barH + frame * 2, '000000', true)
	makeHudBox('vSliceHealthBack', barX, barY, barW, barH, '211A24', true)
	makeHudBox('vSliceHealthDad', barX, barY, barW / 2, barH, 'FF2630', true)
	makeHudBox('vSliceHealthBf', barX + barW / 2, barY, barW / 2, barH, '72FF48', true)
	makeHudBox('vSliceHealthDivider', barX + barW / 2 - 2, barY - 3, 4, barH + 6, '000000', true)

	setProperty('scoreTxt.y', barY + 18)
	setProperty('scoreTxt.size', 18)
	setProperty('scoreTxt.alignment', 'left')

	created = true
	updateVSliceHealthBar()
end

function onUpdatePost(elapsed)
	if not created then return end

	if not SliceHub() then
		for i = 1, #tags do
			setProperty(tags[i] .. '.visible', false)
		end
		return
	end

	updateVSliceHealthBar()
end

function updateVSliceHealthBar()
	local percent = getProperty('healthBar.percent')
	if percent == nil then percent = 50 end
	local hudAlpha = healthBarAlpha or 1

	local divider = barX + (barW * clamp(percent, 0, 100) / 100)
	local dadW = clamp(divider - barX, minFill, barW)
	local bfW = clamp((barX + barW) - divider, minFill, barW)

	for i = 1, #tags do
		setProperty(tags[i] .. '.visible', true)
		setProperty(tags[i] .. '.alpha', hudAlpha)
	end

	setGraphicSize('vSliceHealthDad', dadW, barH)
	setGraphicSize('vSliceHealthBf', bfW, barH)
	setProperty('vSliceHealthBf.x', divider)
	setProperty('vSliceHealthDivider.x', divider - 2)

	local iconY = barY - 38
	setProperty('iconP2.x', divider - 80)
	setProperty('iconP1.x', divider - 22)
	setProperty('iconP2.y', iconY)
	setProperty('iconP1.y', iconY)
	setProperty('iconP2.alpha', hudAlpha)
	setProperty('iconP1.alpha', hudAlpha)

	setProperty('scoreTxt.x', barX + barW - 190)
	setProperty('scoreTxt.y', barY + 18)
	setProperty('scoreTxt.width', 220)
	setProperty('scoreTxt.text', botPlay and 'Bot Play enabled' or ('Score: ' .. tostring(score or 0)))
end
