hook.Add("Initialize", "Multi-Parent", function()
	local ENT 			= FindMetaTable("Entity")
	local SetParent     = ENT.SetParent

	function ENT:SetParent(Parent, Attachment)
		local OldParent     = self:GetParent()
		local OldAttachment = self:GetParentAttachment()

		if Parent == OldParent and OldAttachment == Attachment then return end -- Don't re-parent to the same thing that's just a waste of time

		SetParent(self, Parent, Attachment)

		if IsValid(OldParent) and OldParent ~= Parent and OldParent._children then -- Parent target has changed
			hook.Run("OnEntityUnparented", self, OldParent, OldAttachment)
		end

		if IsValid(Parent) then -- Parenting to a new entity
			self:CallOnRemove("UnparentOnRemove", function( Ent ) -- Have entities unparent when getting removed
				SetParent(Ent, nil)
			end)

			hook.Run("OnEntityParented", self, Parent, Attachment, OldParent)
		else -- Removing parent
			self:RemoveCallOnRemove("UnparentOnRemove")

			hook.Run("OnEntityUnparented", self, OldParent, OldAttachment)
		end
	end
end)