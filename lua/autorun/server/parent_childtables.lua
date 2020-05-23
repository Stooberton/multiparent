hook.Add("Initialize", "Multi-Parent", function()
	local ENT       = FindMetaTable( "Entity" )
	local SetParent = ENT.SetParent


	function ENT:SetParent( Parent, Attachment )
		local OldParent     = self:GetParent()
		local OldAttachment = self:GetParentAttachment()

		if Parent == OldParent and OldAttachment == Attachment then return end -- Don't re-parent to the same thing that's just a waste of time

		SetParent(self, Parent, Attachment)

		if IsValid(OldParent) and OldParent ~= Parent and OldParent._children then -- Parent target has changed
				OldParent._children[self] = nil

			if not next(OldParent._children) then -- Remove the table if empty
				OldParent._children = nil
			end
		end

		if IsValid(Parent) then -- Parenting to a new entity
			Parent._children = Parent._children or {}
			Parent._children[self] = self -- Add to that entity's "children" table

			self:CallOnRemove("UnparentOnRemove", function( Ent ) -- Have entities unparent when getting removed
				SetParent(Ent, nil)
			end)

			hook.Run("OnEntityParented", self, Parent, Attachment, OldParent)
		else
			self:RemoveCallOnRemove("UnparentOnRemove") -- Cleaning up after ourselves

			hook.Run("OnEntityUnparented", self, OldParent, OldAttachment)
		end
	end

	function ENT:GetChildren()
		return self._children or {}
	end
end)