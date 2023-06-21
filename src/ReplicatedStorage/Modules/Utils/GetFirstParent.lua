--[[
	Returns the root/outermost parent of an instance.

	@param instance Instance
	@param optionalAncestor Instance?

	@return outermostParent Instance
]]

return function(instance: Instance, optionalAncestor: Instance?)
	local ancestor = optionalAncestor or workspace

	if not instance:IsDescendantOf(ancestor) then
		error(`Instance {instance:GetFullName()} is not a descendant of {ancestor:GetFullName()}.`)
	end

	local parent = instance.Parent

	while parent ~= ancestor do
		instance = parent
		parent = instance.Parent
	end

	return instance
end
