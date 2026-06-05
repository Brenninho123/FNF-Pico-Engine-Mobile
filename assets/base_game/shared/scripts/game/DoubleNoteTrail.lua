local distX = {-20, 0, 0, 20}
local distY = {0, 15, -15, 0}
local ass = 'cubeIn'
local c = 100
local krilin = 'hardlight'
local dur = 5
local alpha = 0.6

local gC = 0
local aG = {}

local prevTime = {bf = 0, dad = 0, gf = 0}
local pred = {bf = '', dad = '', gf = ''}
local susdir = {bf = '', dad = '', gf = ''}

function HomeroChino(character, id, d, t, sus)
    local strumTime = getPropertyFromGroup('notes', id, 'strumTime')
    local isGfNote = getPropertyFromGroup('notes', id, 'gfNote')
    local char = isGfNote and 'gf' or character

    --debugPrint('no sirve', 'yellow')
    
    if not sus then
        if prevTime[char] == strumTime then
            ghostTrail(char, pred[char])
            susdir[char] = pred[char]
        end
        prevTime[char] = strumTime
        pred[char] = d
    else
        ghostSustain(char, susdir[char])
    end
end

function goodNoteHit(id, d, t, sus)
    HomeroChino('boyfriend', id, d, t, sus)
end

function opponentNoteHit(id, d, t, sus)
    HomeroChino('dad', id, d, t, sus)
end

function getIconColor(chr)
    local arr = getProperty(chr .. ".healthColorArray")
    local intensity = 255 - math.floor((c / 100) * 255)
    return getColorFromHex(string.format('%.2x%.2x%.2x', 
        math.min(arr[1] + intensity, 255), 
        math.min(arr[2] + intensity, 255), 
        math.min(arr[3] + intensity, 255)))
end

function ghostSustain(char, dir)
    local gN = char .. 'Ghost' .. (gC - 1)
    if getProperty(gN .. '.visible') then
        cancelTween(gN .. 'fadeOut')
        cancelTween(gN .. 'X')
        cancelTween(gN .. 'Y')
        
        setProperty(gN .. '.alpha', 0.7)
        setProperty(gN .. '.x', getProperty(char .. '.x'))
        setProperty(gN .. '.y', getProperty(char .. '.y'))
        
        doTweenAlpha(gN .. 'fadeOut', gN, 0, 0.3, 'linear')
        doTweenX(gN .. 'X', gN, getProperty(gN .. '.x') + distX[dir + 1], 0.3, 'linear')
        doTweenY(gN .. 'Y', gN, getProperty(gN .. '.y') + distY[dir + 1], 0.3, 'linear')
        playAnim(gN, getProperty('singAnimations')[dir + 1], true)
    end
end

function ghostTrail(char, dir)
    local gId = char .. 'Ghost' .. gC
    local grp = (char == 'mom') and 'dad' or char
    
    createInstance(gId, 'funkin.data.characters.Character', {
        getProperty(char .. '.x'), 
        getProperty(char .. '.y'), 
        getProperty(char .. '.curCharacter'), 
        getProperty(char .. '.isPlayer')
    })
    
    local props = {'antialiasing', 'offset.x', 'offset.y', 'scale.x', 'scale.y', 'flipX', 'flipY', 'visible'}
    for _, prop in ipairs(props) do
        setProperty(gId .. '.' .. prop, getProperty(char .. '.' .. prop))
    end
    
    setProperty(gId .. '.color', getIconColor(char))
    setProperty(gId .. '.alpha', alpha * getProperty(char .. '.alpha'))
    setBlendMode(gId, krilin)
    
    addInstance(gId)
    setObjectOrder(gId, getObjectOrder(grp .. 'Group') - 0.1)
    playAnim(gId, getProperty('singAnimations')[dir + 1], true)
    
    local startX, startY = getProperty(gId .. '.x'), getProperty(gId .. '.y')
    
    doTweenAlpha(gId .. 'fadeOut', gId, 0, stepCrochet * 0.001 * dur, ass)
    doTweenX(gId .. 'X', gId, startX + distX[dir + 1], dur, ass)
    doTweenY(gId .. 'Y', gId, startY + distY[dir + 1], dur, ass)
    
    aG[gId] = true
    gC = gC + 1
end

function onTweenCompleted(tag)
    for gId, _ in pairs(aG) do
        if tag == gId .. 'fadeOut' then
            callMethod(gId..'.kill', {''})
            callMethod('variables.remove', {gId})
            callMethod('remove', {instanceArg(gId)})
            callMethod(gId..'.destroy', {''})
            aG[gId] = nil
            break
        end
    end
end