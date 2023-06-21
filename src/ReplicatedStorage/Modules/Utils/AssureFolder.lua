--[[
    Returns a folder with the given name, creating it if it doesn't exist.

    @param folderName string
    @param parent Instance

    @return folder Instance
]]
return function(folderName: string, parent: Instance)
	assert(typeof(folderName) == "string", "folderName must be a string")
	assert(typeof(parent) == "Instance", "parent must be an Instance")

	local folder = parent:FindFirstChild(folderName)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end

	return folder
end
