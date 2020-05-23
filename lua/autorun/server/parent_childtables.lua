hook.Add("Initialize", "Multi-Parent", function()
	local ENT       = FindMetaTable( "Entity" )
	local SetParent = ENT.SetParent


	function ENT:SetParent( Parent, Attachment )

		local OldParent = self:GetParent()

		if Parent == OldParent and self:GetParentAttachment() == Attachment then return end -- Don't re-parent to the same thing that's just a waste of time

		SetParent(self, Parent, Attachment)

		if IsValid(OldParent) and OldParent ~= Parent then -- Parent target has changed
			if OldParent._children then -- This should always be true... But just in case
				OldParent._children[self] = nil

				if not next(OldParent._children) then -- Remove the table if empty
					OldParent._children = nil
				end
			end

			self:RemoveCallOnRemove("UnparentOnRemove") -- Cleaning up after ourselves
		end

		if IsValid(Parent) then -- Parenting to a new entity
			Parent._children = Parent._children or {}
			Parent._children[self] = self -- Add to that entity's "children" table

			self:CallOnRemove("UnparentOnRemove", function( Ent ) -- Have entities unparent when getting removed
				SetParent(Ent, nil)
			end)
		end

	end

	function ENT:GetChildren()
		return self._children or {}
	end
end)