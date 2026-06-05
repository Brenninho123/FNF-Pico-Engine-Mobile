local NOTE_TYPE = 'Philly Extra Note'
local SONG_SCRIPT = 'scripts/songs/philly-nice-remix/script'

function onCreate()
	if not isPhillyRemixStage() then return end

	for i = 0, getProperty('unspawnNotes.length') - 1 do
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == NOTE_TYPE then
			setPropertyFromGroup('unspawnNotes', i, 'noAnimation', true)
			setPropertyFromGroup('unspawnNotes', i, 'noMissAnimation', true)
			setPropertyFromGroup('unspawnNotes', i, 'ignoreNote', false)
		end
	end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if noteType == NOTE_TYPE and isPhillyRemixStage() then
		callScript(SONG_SCRIPT, 'playPhillyExtraBySide', {true, direction, isSustainNote})
	end
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
	if noteType == NOTE_TYPE and isPhillyRemixStage() then
		callScript(SONG_SCRIPT, 'playPhillyExtraBySide', {false, direction, isSustainNote})
	end
end

function isPhillyRemixStage()
	return curStage == 'philly_remix' or curStage == 'philly-remix' or curStage == 'phillyTrainRemix'
end
