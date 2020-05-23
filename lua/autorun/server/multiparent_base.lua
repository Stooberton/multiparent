hook.Add("Initialize", "Multi-Parent", function()
	local ENT 			= FindMetaTable("Entity")
	local SetParent     = ENT.SetParent
	local GetParent     = ENT.GetParent

	local MODEL = "models/bull/gates/capacitor.mdl" -- Parenting interceptor model
	local VALIDPATHS = { -- Don't need to intercept the parent if parenting to a wire model anyway
		beer = true,
		blacknecro = true,
		bull = true,
		--cheeze = true, Cheeze models don't seem to work
		cyborgmatt = true,
		["expression 2"] = true,
		hammy = true,
		holograms = true,
		jaanus = true,
		["killa-x"] = true,
		kobilica = true,
		venompapa = true,
		wingf0x = true,
		led = true,
		led2 = true,
		segment = true,
		segment2 = true,
		segment3 = true
	}

	local function IsWireModel(Ent)
		local Path = string.Explode("/", Ent:GetModel())

		return VALIDPATHS[Path[2]] == true
	end

	local function AddChild(Ent, Parent)
		Parent._children = Parent._children or {}
		Parent._children[Ent] = Ent
	end

	local function RemoveChild(Ent, Parent)
		Parent._children[Ent] = nil

		if not next(Parent._children) then -- Remove the table if empty
			Parent._children = nil
		end
	end

	local function RemoveInterceptor(Ent)
		Ent._parent = nil

		local Int = Ent._interceptor

		if not IsValid(Int) then return end -- Just in case?

		Int[Ent] = nil

		if not next(Int._children) then -- Remove the interceptor if it has no more children
			Int:Remove()

			local Parent = Int:GetParent()

			Parent._interceptors[Int] = nil

			if not next(Parent._interceptors) then
				Parent._interceptors = nil
			end
		end
	end

	local function AddInterceptor(Ent, Parent, Attachment)
		if IsWireModel(Parent) then -- Normal behavior if it's a wire model
			SetParent(Ent, Parent, Attachment)
		elseif Parent.Interceptors and Parent._interceptor[Attachment] then -- Interceptor already exists between Ent and Parent, use that one...
			SetParent(Ent, Parent._interceptor[Attachment])
		else -- Make a new one
			local Int = ents.Create("base_anim")
				Int:SetPos(Ent:GetPos())
				Int:SetSolid(SOLID_NONE)
				Int:SetMoveType(MOVETYPE_NONE)
				Int:SetNoDraw(true)
				Int:SetModel(MODEL)

				SetParent(Ent, Int) -- Parent Ent to the interceptor
				SetParent(Int, Parent, Attachment) -- and the interceptor to the parent

				Ent._parent   = Parent -- Keep track of intended parent for GetParent to return
				Int._children = {Ent = Ent} -- Keep track of the interceptors actual children in order to remove it when it has no more

				Parent._interceptor = Parent._interceptor or {} -- Keep track of the interceptors attached to an entity to know if one exists already and can be used instead of making a new one
				Parent._interceptor[Attachment] = Int
		end
	end


	function ENT:SetParent( Parent, Attachment)
		print(self, Parent)
		local OldParent     = self:GetParent()
		local OldAttachment = self:GetParentAttachment()

		if Parent == OldParent and OldAttachment == Attachment then return end -- Don't re-parent to the same thing that's just a waste of time

		if IsValid(Parent) and Parent:GetClass() == "predicted_viewmodel" then -- Ignore viewmodels
			SetParent(self, Parent, Attachment)

			return
		end

		if IsValid(OldParent) and OldParent ~= Parent and OldParent._children then -- Parent target has changed
			RemoveChild(self, OldParent)
			RemoveInterceptor(self, OldParent)
		end

		if IsValid(Parent) then -- Parenting to a new entity
			AddChild(self, Parent)
			AddInterceptor(self, Parent, Attachment or 0)

			self:CallOnRemove("UnparentOnRemove", function( Ent ) -- Have entities unparent when getting removed
				SetParent(Ent, nil)
			end)

			hook.Run("OnEntityParented", self, Parent, Attachment, OldParent)
		else -- Removing parent
			self:RemoveCallOnRemove("UnparentOnRemove") -- Cleaning up after ourselves

			hook.Run("OnEntityUnparented", self, OldParent, OldAttachment)
		end
	end

	function ENT:GetChildren()
		return self._children or {}
	end

	function ENT:GetParent()
		return self._parent or GetParent(self)
	end
end)