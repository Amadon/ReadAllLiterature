CollectAllLiterature = {
	collectableArray = {}
}

-- Get the book list for the player or group,
-- depending on if the player is in a group or not.
function CollectAllLiterature:getBookList()
    local player = getPlayer()  -- Get the player object.
    local currentGroup = player:getGroup()  -- Get the player's current group.
    local modData  -- Declare the modData variable.

    -- Check if the player is in a group.
    if currentGroup then
        modData = currentGroup:getModData()  -- Get the group's modData.
    else
        modData = player:getModData()  -- Get the player's modData.
    end

    -- Check if the CollectAllLiterature field exists in the modData.
    if not modData.CollectAllLiterature then
        modData.CollectAllLiterature = {}  -- Create the CollectAllLiterature field.
        modData.CollectAllLiterature.bookList = {}  -- Create the bookList field.
    end

    return modData.CollectAllLiterature.bookList  -- Return the book list.
end


function CollectAllLiterature:addToBookList(bookItem)
	local isCollectable = CollectAllLiterature:isCollectable(bookItem)
	
	if isCollectable then
		local booksList = CollectAllLiterature:getBookList()
		local fullName = bookItem:getFullType()
		table.insert(booksList, fullName)
	end
	
	return isCollectable
end

function CollectAllLiterature:isInBookList(item)
	local isInBookList = false
	local fullBookName = item:getFullType()
    local bookList = CollectAllLiterature:getBookList()
	if bookList then
		for _, book in pairs(bookList) do
			if book == fullBookName then
				isInBookList = true
			end
		end
	end
	return isInBookList
end

function CollectAllLiterature:isRecipe(item)
	return item:getTeachedRecipes()
end

function CollectAllLiterature:isSkillBook(item)
	return SkillBook[item:getSkillTrained()]
end

--[[
This function checks whether an item is collectable based on several conditions.

The conditions are:
- the item is not already in the collection book list
- the item is either a literature item (i.e., a skill book or a recipe), or a map

Input:
- item: the item to check

Output:
- a boolean indicating whether the item is collectable
]]
function CollectAllLiterature:isCollectable(item)
    -- If the item is already in the collection book list, it is not collectable
    if CollectAllLiterature:isInBookList(item) then
        return false
    end

	-- By default, the item is not considered to be literature
    local isLiterature = false
    -- Check if the item category is "Literature"
    local itemCategory = item:getCategory()
    if itemCategory == "Literature" then
	    -- If the item category is "Literature", check if it is a skill book or a recipe
        local isSkillBook = ModOptions.getOption("Collect", "Books") and CollectAllLiterature:isSkillBook(item)
		local isRecipe =  ModOptions.getOption("Collect", "Recipes") and CollectAllLiterature:isRecipe(item)
        -- If the item is either a skill book or a recipe, it is considered to be literature
        isLiterature = isSkillBook or isRecipe
    end
	-- Check if the item type is "Map"
    local isMap = ModOptions.getOption("Collect", "Maps") and item:getType() == "Map"
    -- Return the result: either the item is literature, or it is a map, or both
    return isLiterature or isMap
end

function CollectAllLiterature:CollectableFilter(container)
	local collectableArray = {}
	if container:getItems():size() > 0 then
		for i = 0, container:getItems():size() -1 do
			local item = container:getItems():get(i)
			if CollectAllLiterature:isCollectable(item) then
				table.insert(collectableArray, item)
			end
		end
	end
	return collectableArray
end

function CollectAllLiterature:perform()
	local playerObj = getPlayer()
	for _, item in ipairs(CollectAllLiterature.collectableArray) do
		if CollectAllLiterature:isCollectable(item) and luautils.haveToBeTransfered(playerObj, item) then
			ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerObj:getInventory()))
		end
	end
end

function CollectAllLiterature:AddCollectButtonEvent(state)
	if state == "end" and not self.onCharacter then
		CollectAllLiterature.collectableArray = CollectAllLiterature:CollectableFilter(self.inventoryPane.inventory)
		local leftSpace = self.lootAll:getRight() + 16
		if self.readButton and self.readButton:isVisible() then
			leftSpace = self.readButton:getRight() + 16
		end
		if (CollectAllLiterature.collectableArray) > 0 then
  			self.collectButton = ISButton:new(leftSpace, 0, 50, self:titleBarHeight(), getText("UI_CollectAllLiterature_Collect_All"), self, CollectAllLiterature.perform);
			self.collectButton:initialise();
			self.collectButton.borderColor.a = 0.0;
			self.collectButton.backgroundColor.a = 0.0;
			self.collectButton.backgroundColorMouseOver.a = 0.7;
			self:addChild(self.collectButton);
			self.collectButton:setVisible(true);
		end
	elseif state == "begin" and not self.onCharacter and self.collectButton then
		self.collectButton:setVisible(false);
	end
end