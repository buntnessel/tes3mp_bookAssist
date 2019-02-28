--heavily modelled after Atkana's decoratorsAid ( https://github.com/Atkana/ )
-- inspired by BookRotate
-- maths taken from BookRotate ( Cydine & Maboroshi Daikon,  http://mw.modhistory.com/download-11-6953) 
-- and Hephs Book Rotation ( http://morrowind.heph.org/)
--28. Feb: uploading a first working version

--list of execution:
-- listen for OnObjectPlace (so, if a player is placing something)
-- check if placedobject is book (by comparing the books name to common refs from morrowind.esm, tamriel rebuilt and mw rebirth)
-- if yes, save the book's UniqueID
-- and then, after calculating which direction the player is facing, change the direction and height of the book
-- by deleting the book the player placed and replacing it with a exact copy with different position & rotation values


local bookAssist = {}



function bookAssist.OnCommand (pid, targetHeight)

	if targetHeight == 0 then
	--0 is used to turn the script off - its useless without height adjustment anyways
	Players[pid].data.customVariables.bookAssistState = 0
	Players[pid]:Save()
	message = "Turning bookAssist off"
	tes3mp.SendMessage(pid, color.Error .. message .. color.Default, false)
	else 
	
	Players[pid].data.customVariables.bookAssistState = 1
	Players[pid].data.customVariables.bookAssistHeight = targetHeight
	Players[pid]:Save()

	tes3mp.LogMessage(enumerations.log.INFO, "bookAssist setting height to " .. targetHeight)
	message = "bookAssist height set to:" .. targetHeight
	tes3mp.SendMessage(pid, color.Error .. message .. color.Default, false)
	 
	end 
end

--listen for object placement events, get their data, then check if they're concerning books
function bookAssist.OnObjectPlace (pid, cellDescription)
--check if the functionality is on

			checkvariable = tonumber(Players[pid].data.customVariables.bookAssistState)
			
if checkvariable == 1 then

	local refId = tes3mp.GetObjectRefId(0)
	local cellId = tes3mp.GetCell(pid)
	tes3mp.LogMessage(enumerations.log.INFO, "bookAssist listening in for: refid = " .. tes3mp.GetObjectRefId(0))
	--check if object is a book
	if ((string.match(tes3mp.GetObjectRefId(0), "bk_")) or (string.match(tes3mp.GetObjectRefId(0), "mr_book_")) or (string.match(tes3mp.GetObjectRefId(0), "T_Bk_")) or (string.match(tes3mp.GetObjectRefId(0), "book")) or (string.match(tes3mp.GetObjectRefId(0), "Book"))) then
	--now begins the magic, calling the gui for the placement change and so on and so forth
	
	--construct and append the unique index of the book
	bookUniqueIndex = tes3mp.GetObjectRefId(0) .. "-" .. tes3mp.GetObjectMpNum(0)
	
	--save the unique index for a short duration to a custom variable on the player
	Players[pid].data.customVariables.bookAssistBook = bookUniqueIndex
	Players[pid]:Save()
	
	selectedBookRef = tes3mp.GetObjectRefId(0)
	selectedBookMpnum = tes3mp.GetObjectMpNum(0)
	
	--output rotation coordinates to console
	
	object = LoadedCells[cellId].data.objectData["0-"..selectedBookMpnum]
	


	bookAssist.objectsUpdate(pid)
end 
	end
end



function bookAssist.objectsUpdate (pid)
-- check if we're turned on
	
			checkvariable = tonumber(Players[pid].data.customVariables.bookAssistState)
			
if checkvariable == 1 then


	--unique id reference: 0-127 , 0 for placed by the server, -127 is the mpnum. every object that's once picked up and placed by the player gets such an unique identifier, therefore when loading celldata
	--we can simply take the first zero as a given. 
	
	local cell = tes3mp.GetCell(pid)
	local splitIndex = Players[pid].data.customVariables.bookAssistBook:split("-")
	local uid = "0-" .. splitIndex[2]
	tes3mp.LogMessage(enumerations.log.INFO, "bookAssist constructs the following unique identifier for it: " .. uid)
	tes3mp.LogMessage(enumerations.log.INFO, "incidentially, bookAssits state is set to " .. Players[pid].data.customVariables.bookAssistState)
	--load the object
	object = LoadedCells[cell].data.objectData[uid]
	
	local refId = object.refId
	local count = object.count or 1
	local charge = object.charge or -1
	local posX, posY, posZ = object.location.posX, object.location.posY, object.location.posZ
	local rotX, rotY, rotZ = object.location.rotX, object.location.rotY, object.location.rotZ
	local refIndex = refIndex
	
	
	for pid, pdata in pairs(Players) do
		if Players[pid]:IsLoggedIn() then
			--First, delete the original
			tes3mp.InitializeEvent(pid)
			tes3mp.SetEventCell(cell)
			tes3mp.SetObjectRefNumIndex(0)
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.AddWorldObject() --?
			tes3mp.SendObjectDelete()
			
			--Now remake it
			-- 360 degrees * 60 = 21600
			-- x 21600, y 0, z 0 = straight north
			-- x 0, y 21600, z 0 = points book down, useless
			-- x 0, y 0, z 21600 = lays book flat on hte ground
			
			--implementation of the book rotate script
			
			
			

		 playerZ = tes3mp.GetRotZ(pid)
		 
		 playerZ = math.deg(playerZ)
		 
		faceDirection = 0

		if playerZ < 0 then
			playerZ = 360 + playerZ
		end

--1	North	315 - 45
--2	East	45 - 135
--3	South	135 - 225
--4	West	225 - 315

		if playerZ >= 315 then
		 faceDirection = 1
		end

		if  playerZ <= 45 then
			faceDirection = 1
		end

		if playerZ > 45 then
			if playerZ < 135 then
				faceDirection = 2
			end
		end

		if playerZ >= 135 then
			if playerZ <= 225 then
				faceDirection = 3
			end
		end

		if playerZ > 225 then
			if playerZ < 315 then
				faceDirection = 4
			end
		end

		rotX = 0
		rotY = 0
		rotZ = 0

									-- VERTICAL
			--adjust height
			if faceDirection == 1 then
				rotY = 270
				rotZ = 270
				end
			if faceDirection == 2 then
				rotX = 270
				end
			if  faceDirection == 3 then
				rotX = 180
				rotY = 270
				rotZ = 270
				end
			if  faceDirection == 4 then
				rotX = 270
				rotZ = 180
			end
			

			rotX = math.rad(rotX)
			rotY = math.rad(rotY)
			rotZ = math.rad(rotZ)

			
			if Players[pid].data.customVariables.bookAssistHeight then
			height = Players[pid].data.customVariables.bookAssistHeight
			else
			height = 13
			end


			--Now remake it
			tes3mp.InitializeEvent(pid)
			tes3mp.SetEventCell(cell)
			tes3mp.SetObjectRefId(refId)
			tes3mp.SetObjectCount(count)
			tes3mp.SetObjectCharge(charge)
			tes3mp.SetObjectPosition(posX, posY, posZ+height)
			tes3mp.SetObjectRotation(rotX, rotY, rotZ)
			tes3mp.SetObjectRefNumIndex(0)
			tes3mp.SetObjectMpNum(splitIndex[2])
			if inventory then
				for itemIndex, item in pairs(inventory) do
					tes3mp.SetContainerItemRefId(item.refId)
					tes3mp.SetContainerItemCount(item.count)
					tes3mp.SetContainerItemCharge(item.charge)

					tes3mp.AddContainerItem()
				end
			end
			
			tes3mp.AddWorldObject()
			tes3mp.SendObjectPlace()
			if inventory then
				tes3mp.SendContainer()
			end

			
				
		end
	end
	
	LoadedCells[cell]:Save() --Not needed, but it's nice to do anyways

	--potentially call gui again to continue placement
	


	return objectsUpdate
	end 
end 


return bookAssist
