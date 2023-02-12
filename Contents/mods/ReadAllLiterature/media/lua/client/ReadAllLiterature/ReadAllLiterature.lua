ReadAllLiterature = {
	readableArray = {}
}

function ReadAllLiterature:isSkillBook(playerObj, item)
	local isSkillBook = false
	local skillBook = SkillBook[item:getSkillTrained()]
	
    if skillBook then
		local perkLevel = playerObj:getPerkLevel(skillBook.perk)
		local minLevel = item:getLvlSkillTrained()
		local maxLevel = item:getMaxLevelTrained()
		if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
			local readPages = playerObj:getAlreadyReadPages(item:getFullType())
			if readPages >= item:getNumberOfPages() then
				isSkillBook = false
			elseif perkLevel >= maxLevel then
				isSkillBook = false
			elseif readPages > 0 then
				isSkillBook = true
			else
				isSkillBook = true
			end
		else
			isSkillBook = false
		end
	end

	return isSkillBook
end

function ReadAllLiterature:isRecipes(playerObj, item)
	local isRecipes = false

	if item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
		if playerObj:getKnownRecipes():containsAll(item:getTeachedRecipes()) then
			isRecipes = false
		else
			isRecipes = true
		end
	end

	return isRecipes
end

function ReadAllLiterature:isReadable(playerObj, item)
	local isReadable = false
	local isLiterature = item:getCategory() == "Literature"
	if isLiterature then
		local isSkillBook = ReadAllLiterature:isSkillBook(playerObj, item)
		local isRecipes = ReadAllLiterature:isRecipes(playerObj, item)
		if  isSkillBook or isRecipes then
			isReadable = true
		end
	end
	return isReadable
end

function ReadAllLiterature:ReadableFilter(container)
	local playerObj = getPlayer()
	local readableArray = {}
	if container:getItems():size() > 0 then
		for i = 0, container:getItems():size() -1 do
			local item = container:getItems():get(i)
			if ReadAllLiterature:isReadable(playerObj, item) then
				table.insert(readableArray, item)
			end
		end
	end
	return readableArray
end

function ReadAllLiterature:perform()
	local playerObj = getPlayer()
	local magazines = {}
	for _, item in ipairs(ReadAllLiterature.readableArray) do
		if ReadAllLiterature:isReadable(playerObj, item) then
			local srcContainer = item:getContainer()
			if luautils.haveToBeTransfered(playerObj, item) then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerObj:getInventory()))
			end
			ISTimedActionQueue.add(ISReadABook:new(playerObj, item, 150))
			if SkillBook[item:getSkillTrained()] then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj ,item,  playerObj:getInventory(), srcContainer))
			else
				table.insert(magazines, item)
				if #magazines >= 5 then
					ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, magazines, playerObj:getInventory(), srcContainer))
					magazines = {}
				end
			end
		end
	end
	if #magazines > 0 then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, magazines, playerObj:getInventory(), srcContainer))
	end
end

function ReadAllLiterature:AddReadButtonEvent(state)
	if state == "end" and not self.onCharacter then
		local leftSpace = self.lootAll:getRight() + 16
		ReadAllLiterature.readableArray = ReadAllLiterature:ReadableFilter(self.inventoryPane.inventory)
		if #(ReadAllLiterature.readableArray) > 0 then
			self.readButton = ISButton:new(leftSpace, 0, 50, self:titleBarHeight(), getText("UI_ReadAllLiterature_Read_All"), self, ReadAllLiterature.perform);
			self.readButton:initialise();
			self.readButton.borderColor.a = 0.0;
			self.readButton.backgroundColor.a = 0.0;
			self.readButton.backgroundColorMouseOver.a = 0.7;
			self:addChild(self.readButton);
			self.readButton:setVisible(true);
		end
	elseif state == "begin" and not self.onCharacter and self.readButton then
		self.readButton:setVisible(false);
	end
end
