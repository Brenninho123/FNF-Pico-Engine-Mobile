local combo = 0
local maxComb = 0
local misses = 0

function onCreate()
    if comboEnabled ~= true then
        return
    end

    makeLuaText("mCombo", 'Max Combo: 0', 200, -8, 259)
    setObjectCamera("mCombo", 'hud')
    setTextColor('mCombo', '0xfff700')
    setTextSize('mCombo', 20)
    addLuaText("mCombo")
    setTextFont('mCombo', "vcr.ttf")
    setTextAlignment('mCombo', 'center')

    makeLuaText("combo", 'Combo: 0', 200, getProperty('mCombo.x'), getProperty('mCombo.y') + 30)
    setObjectCamera("combo", 'hud')
    setTextColor('combo', '0xffffff')
    setTextSize('combo', 20)
    addLuaText("combo")
    setTextFont('combo', "vcr.ttf")
    setTextAlignment('combo', 'center')

    makeLuaText("miss", 'Misses: 0', 200, getProperty('combo.x'), getProperty('combo.y') + 30)
    setObjectCamera("miss", 'hud')
    setTextColor('miss', '0x36eaf7')
    setTextSize('miss', 20)
    addLuaText("miss")
    setTextFont('miss', "vcr.ttf")
    setTextAlignment('miss', 'center')
    setProperty('miss.alpha', tonumber(0.8))
end

function onCreatePost()
    maxComb = 0
end

function onUpdate(elapsed)
    if comboEnabled ~= true then
        return
    end

    if maxComb < combo then
        maxComb = combo
    end

    setTextString('combo', 'Combo: ' .. combo)
    setTextString('mCombo', 'Max Combo: ' .. maxComb)
    setTextString('miss', 'Misses: ' .. misses)

    if misses > 0 then
        setTextColor('miss', 'ff0000')
        setProperty('miss.alpha', tonumber(1))
    else
        setTextColor('miss', '0x36eaf7')
        setProperty('miss.alpha', tonumber(0.8))
    end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    if comboEnabled ~= true then
        return
    end

    if isSustainNote then
        return
    end

    combo = combo + 1
end

function noteMiss()
    if comboEnabled ~= true then
        return
    end

    combo = 0
    misses = misses + 1
end
