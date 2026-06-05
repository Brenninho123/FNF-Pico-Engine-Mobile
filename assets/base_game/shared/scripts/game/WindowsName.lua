local appTitle = nil
local displayNameSongs = nil
local displayNameBy = nil
local titleWasChanged = false

local function cleanText(value)
    if value == nil then
        return ''
    end

    value = tostring(value)
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    return value
end

local function getFallbackSongName()
    local name = cleanText(songName)
    if name == '' then
        name = cleanText(getProperty('SONG.song'))
    end

    return name
end

local function getAppTitle()
    if appTitle == nil or appTitle == '' then
        appTitle = cleanText(getPropertyFromClass('lime.app.Application', 'current.window.title'))
        local divider = appTitle:find('|', 1, true)
        if divider ~= nil then
            appTitle = cleanText(appTitle:sub(1, divider - 1))
        end
    end

    return appTitle
end

local function restoreAppTitle()
    local title = getAppTitle()
    if title ~= '' then
        setPropertyFromClass('lime.app.Application', 'current.window.title', title)
    end
    titleWasChanged = false
end

local function applyWindowsName()
    local title = getAppTitle()
    local name = cleanText(displayNameSongs)
    local by = cleanText(displayNameBy)

    if name == '' then
        name = getFallbackSongName()
    end

    if title == '' and name == '' then
        return
    end

    if name ~= '' then
        if title ~= '' then
            title = title .. ' | ' .. name
        else
            title = name
        end
    end

    if by ~= '' then
        title = title .. ' | By ' .. by
    end

    setPropertyFromClass('lime.app.Application', 'current.window.title', title)
    titleWasChanged = true
end

function setDisplayNameSongs(name, by)
    displayNameSongs = cleanText(name)
    displayNameBy = cleanText(by)
    applyWindowsName()
end

function setDisplayNameSongsBy(by)
    displayNameBy = cleanText(by)
    applyWindowsName()
end

function setDisplayNameSongsName(name)
    displayNameSongs = cleanText(name)
    applyWindowsName()
end

function setWindowsName(name, by)
    setDisplayNameSongs(name, by)
end

function setWindowsNameBy(by)
    setDisplayNameSongsBy(by)
end

function setWindowsNameSong(name)
    setDisplayNameSongsName(name)
end

function onCreatePost()
    applyWindowsName()
end

function onEndSong()
    restoreAppTitle()
end

function onDestroy()
    restoreAppTitle()
end
