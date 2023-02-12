require "TimedActions/ISInventoryTransferAction"
require "ReadAllLiterature/CollectAllLiterature"

local originalISInventoryTransferActionNew = ISInventoryTransferAction.new

function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
	if getPlayer():getInventory() == destContainer then
    	CollectAllLiterature:addToBookList(item)
	end
	return originalISInventoryTransferActionNew(self, character, item, srcContainer, destContainer, time)
end