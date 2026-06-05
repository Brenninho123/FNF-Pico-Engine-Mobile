local MIN_COMBO = 20
local MILESTONE_STEP = 10

local COMBO_TAG = 'comboMilestone'
local COMBO_SPRITE = 'comboMilestoneSprite'
local COMBO_ASSET = 'ui/popup/funkin/combo'

local COMBO_X = 460
local COMBO_Y = 180
local COMBO_SCALE = 0.7
local COMBO_IN_TIME = 0.12
local COMBO_STAY = 0.45
local COMBO_OUT_TIME = 0.25

local lastMilestone = 0

function onSongStart()
    lastMilestone = 0
end

function onUpdateScore(miss)
    if miss then
        lastMilestone = 0
        return
    end

    local curCombo = getProperty('combo') or 0
    if curCombo < MIN_COMBO then
        return
    end

    if curCombo % MILESTONE_STEP ~= 0 then
        return
    end

    if curCombo == lastMilestone then
        return
    end

    lastMilestone = curCombo
    showComboSprite()
end

function showComboSprite()
    cancelTimer(COMBO_TAG .. 'Out')
    cancelTimer(COMBO_TAG .. 'Remove')
    cancelTween(COMBO_TAG .. 'In')
    cancelTween(COMBO_TAG .. 'ScaleXIn')
    cancelTween(COMBO_TAG .. 'ScaleYIn')
    cancelTween(COMBO_TAG .. 'MoveIn')
    cancelTween(COMBO_TAG .. 'FadeOut')
    cancelTween(COMBO_TAG .. 'MoveOut')

    removeComboSprite()

    makeLuaSprite(COMBO_SPRITE, COMBO_ASSET, COMBO_X, COMBO_Y)
    setObjectCamera(COMBO_SPRITE, 'hud')
    setProperty(COMBO_SPRITE .. '.alpha', 0)
    setProperty(COMBO_SPRITE .. '.scale.x', COMBO_SCALE * 0.8)
    setProperty(COMBO_SPRITE .. '.scale.y', COMBO_SCALE * 0.8)
    addLuaSprite(COMBO_SPRITE, true)

    doTweenAlpha(COMBO_TAG .. 'In', COMBO_SPRITE, 1, COMBO_IN_TIME, 'circOut')
    doTweenX(COMBO_TAG .. 'ScaleXIn', COMBO_SPRITE .. '.scale', COMBO_SCALE, COMBO_IN_TIME, 'backOut')
    doTweenY(COMBO_TAG .. 'ScaleYIn', COMBO_SPRITE .. '.scale', COMBO_SCALE, COMBO_IN_TIME, 'backOut')
    doTweenY(COMBO_TAG .. 'MoveIn', COMBO_SPRITE, COMBO_Y - 20, COMBO_IN_TIME, 'circOut')

    runTimer(COMBO_TAG .. 'Out', COMBO_STAY, 1)
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == COMBO_TAG .. 'Out' then
        if luaSpriteExists(COMBO_SPRITE) then
            doTweenAlpha(COMBO_TAG .. 'FadeOut', COMBO_SPRITE, 0, COMBO_OUT_TIME, 'expoIn')
            doTweenY(COMBO_TAG .. 'MoveOut', COMBO_SPRITE, COMBO_Y - 35, COMBO_OUT_TIME, 'expoIn')
        end
        runTimer(COMBO_TAG .. 'Remove', COMBO_OUT_TIME + 0.02, 1)
    elseif tag == COMBO_TAG .. 'Remove' then
        removeComboSprite()
    end
end

function onGameOver()
    lastMilestone = 0
    removeComboSprite()
end

function removeComboSprite()
    if luaSpriteExists(COMBO_SPRITE) then
        removeLuaSprite(COMBO_SPRITE, true)
    end
end
