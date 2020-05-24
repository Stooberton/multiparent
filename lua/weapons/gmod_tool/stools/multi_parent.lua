TOOL.Category		= "Constraints"
TOOL.Name			= "#tool.multi_parent.listname"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "tool.multi_parent.name", "Multi-Parent Tool" )
	language.Add( "tool.multi_parent.listname", "Multi-Parent" )
	language.Add( "tool.multi_parent.desc", "Parent multiple props to one prop." )
	language.Add( "tool.multi_parent.0", "Primary: Select a prop. (Shift to select all, Use to area select) Secondary: Parent all selected entities to prop. Reload: Clear Targets." )
	language.Add( "tool.multi_parent.removeconstraints", "Remove Constraints" )
	language.Add( "tool.multi_parent.nocollide", "No Collide" )
	language.Add( "tool.multi_parent.weld", "Weld" )
	language.Add( "tool.multi_parent.disablecollisions", "Disable Collisions" )
	language.Add( "tool.multi_parent.weight", "Set weight" )
	language.Add( "tool.multi_parent.disableshadow", "Disable Shadows" )
	language.Add( "tool.multi_parent.ignoregate", "Ignore parenting gates")
	language.Add( "tool.multi_parent.removeconstraints.help", "Remove all constraints before parenting (cannot be undone!)." )
	language.Add( "tool.multi_parent.nocollide.help", "Checking this creates a no collide constraint between the entity and parent. Unchecking will save on constraints (read: lag).")
	language.Add( "tool.multi_parent.weld.help", "Checking this creates a weld between the entity and parent. This will retain the physics on parented props and you will still be able to physgun them, but it will cause more lag (not recommended)." )
	language.Add( "tool.multi_parent.disablecollisions.help", "Disable all collisions before parenting." )
	language.Add( "tool.multi_parent.weight.help", "Checking this will set the entity's weight to whatever the slider is set to above before parenting." )
	language.Add( "tool.multi_parent.disableshadow.help", "Disables shadows for parented entities." )
	language.Add( "tool.multi_parent.ignoregate.help", "Ignores any parenting gates set on the target entity. Parenting gates will redirect parenting to themselves instead of the parenting gate's parent.")
	language.Add( "Undone_Multi-Parent", "Undone Multi-Parent" )
end

TOOL.ClientConVar[ "removeconstraints" ] = "0"
TOOL.ClientConVar[ "nocollide" ] = "0"
TOOL.ClientConVar[ "disablecollisions" ] = "0"
TOOL.ClientConVar[ "weld" ] = "0"
TOOL.ClientConVar[ "weight" ] = "0"
TOOL.ClientConVar[ "mass" ] = "0.01"
TOOL.ClientConVar[ "radius" ] = "512"
TOOL.ClientConVar[ "disableshadow" ] = "0"
TOOL.ClientConVar[ "ignoregate" ] = "0"

local VALIDPATHS = { -- These wire models fix the parent-trace issue for whatever reason
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

	return VALIDPATHS[Path[2]]
end

duplicator.RegisterEntityModifier("Parent-Gate", function(Ply, Entity, Args)
	timer.Simple(0, function()
		if IsValid(Entity) and IsValid(Entity:GetParent()) then
			Entity:GetParent()._parentgate = Entity
		end
	end)
end)

function TOOL.BuildCPanel( panel )
	panel:AddControl("Slider", {
		Label = "Auto Select Radius:",
		Type = "integer",
		Min = "64",
		Max = "1024",
		Command = "multi_parent_radius"
	} )
	panel:AddControl("Slider", {
		Label = "Set Mass:",
		Type = "float",
		Min = "0.01",
		Max = "50000",
		Command = "multi_parent_mass"
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.removeconstraints",
		Command = "multi_parent_removeconstraints",
		Help = true
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.nocollide",
		Command = "multi_parent_nocollide",
		Help = true
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.weld",
		Command = "multi_parent_weld",
		Help = true
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.disablecollisions",
		Command = "multi_parent_disablecollisions",
		Help = true
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.weight",
		Command = "multi_parent_weight",
		Help = true
	} )
	panel:AddControl( "Checkbox", {
		Label = "#tool.multi_parent.disableshadow",
		Command = "multi_parent_disableshadow",
		Help = true
	} )
	panel:AddControl("Checkbox", {
		Label = "#tool.multi_parent.ignoregate",
		Command = "multi_parent_ignoregate",
		Help = true
	})
end

TOOL.enttbl = {}

function TOOL:IsPropOwner( ply, ent )
	if CPPI then
		return ent:CPPIGetOwner() == ply
	else
		for k, v in pairs( g_SBoxObjects ) do
			for b, j in pairs( v ) do
				for _, e in pairs( j ) do
					if e == ent and k == ply:UniqueID() then return true end
				end
			end
		end
	end
	return false
end

function TOOL:IsSelected( ent )
	local eid = ent:EntIndex()
	return self.enttbl[eid] ~= nil
end

function TOOL:Select( ent )
	local eid = ent:EntIndex()
	if not self:IsSelected( ent ) then -- Select
		local col = Color(0, 0, 0, 0)
		col = ent:GetColor()
		self.enttbl[eid] = col
		ent:SetColor( Color(0, 255, 0, 100) )
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	end
end

function TOOL:Deselect( ent )
	local eid = ent:EntIndex()
	if self:IsSelected( ent ) then -- Deselect
		local col = self.enttbl[eid]
		ent:SetColor( col )
		self.enttbl[eid] = nil
	end
end

function TOOL:ParentCheck( child, parent )
	while IsValid( parent ) do
		if child == parent then
			return false
		end
		parent = parent:GetParent()
	end
	return true
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if (not ply:KeyDown( IN_USE )) and trace.Entity:IsWorld() then return false end

	local ent = trace.Entity

	if ply:KeyDown( IN_USE ) then -- Area select function
		local SelectedProps = 0
		local Radius = math.Clamp( self:GetClientNumber( "radius" ), 64, 1024 )

		for k, v in pairs( ents.FindInSphere( trace.HitPos, Radius ) ) do
			if v:IsValid() and not self:IsSelected( v ) and self:IsPropOwner( ply, v ) then
				self:Select( v )
				SelectedProps = SelectedProps + 1
			end
		end

		ply:PrintMessage( HUD_PRINTTALK, "Multi-Parent: " .. SelectedProps .. " props were selected." )
	elseif ply:KeyDown( IN_SPEED ) then -- Select all constrained entities
		local SelectedProps = 0

		for k, v in pairs( constraint.GetAllConstrainedEntities( ent ) ) do
			self:Select( v )
			SelectedProps = SelectedProps + 1
		end

		ply:PrintMessage( HUD_PRINTTALK, "Multi-Parent: " .. SelectedProps .. " props were selected." )
	elseif self:IsSelected( ent ) then -- Ent is already selected, deselect it
		self:Deselect( ent )
	else -- Select single entity
		self:Select( ent )
	end

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	if trace.Entity:IsWorld() then return false end
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	if self:GetOwner():KeyDown(IN_SPEED) then -- Shift + Right
		if not IsWireModel(trace.Entity) then
			self:GetOwner():PrintMessage(HUD_PRINTTALK, "Multi-Parent: Target is not a valid model.")
			return false
		end
		if not IsValid(trace.Entity:GetParent()) then
			self:GetOwner():PrintMessage(HUD_PRINTTALK, "Multi-Parent: Target has no parent.")
			return false
		end

		if trace.Entity:GetParent()._parentgate == trace.Entity then
			self:GetOwner():PrintMessage(HUD_PRINTTALK, "Multi-Parent: Parent gate removed.")
			trace.Entity:GetParent()._parentgate = nil

			duplicator.ClearEntityModifier(trace.Entity, "Parent-Gate")
		else
			self:GetOwner():PrintMessage(HUD_PRINTTALK, "Multi-Parent: Parent gate selected.")
			trace.Entity:GetParent()._parentgate = trace.Entityj

			duplicator.StoreEntityModifier(trace.Entity, "Parent-Gate", {["Gate"] = true})
		end
	elseif table.Count( self.enttbl ) < 1 then return -- Nothing to parent
	else
		local _nocollide = tobool( self:GetClientNumber( "nocollide" ) )
		local _disablecollisions = tobool( self:GetClientNumber( "disablecollisions" ) )
		local _weld = tobool( self:GetClientNumber( "weld" ) )
		local _removeconstraints = tobool( self:GetClientNumber( "removeconstraints" ) )
		local _weight = tobool( self:GetClientNumber( "weight" ) )
		local _mass = math.Clamp(self:GetClientNumber("mass"), 0.01, 50000)
		local _disableshadow = tobool( self:GetClientNumber( "disableshadow" ) )
		local _usegate = not tobool(self:GetClientNumber("gate"))

		local ent = (IsValid(trace.Entity._parentgate) and _usegate) and trace.Entity._parentgate or trace.Entity

		local undo_tbl = {}

		undo.Create( "Multi-Parent" )
		for k, v in pairs( self.enttbl ) do
			local prop = Entity( k )
			if IsValid( prop ) and self:ParentCheck( prop, ent ) then
				local phys = prop:GetPhysicsObject()
				if IsValid( phys ) then
					local data = {}

					if _removeconstraints then
						constraint.RemoveAll( prop )
					end

					if _nocollide then
						undo.AddEntity( constraint.NoCollide( prop, ent, 0, 0 ) )
					end

					if _disablecollisions then
						data.ColGroup = prop:GetCollisionGroup()
						prop:SetCollisionGroup( COLLISION_GROUP_WORLD )
					end

					if _weld then
						undo.AddEntity( constraint.Weld( prop, ent, 0, 0 ) )
					end

					if _weight then
						data.Mass = phys:GetMass()
						phys:SetMass( _mass )
						duplicator.StoreEntityModifier( prop, "mass", { Mass = _mass } )
					end

					if _disableshadow then
						data.DisabledShadow = true
						prop:DrawShadow( false )
					end

					-- Unfreeze and sleep the physobj
					phys:EnableMotion( true )
					phys:Sleep()

					-- Restore original color and parent
					prop:SetColor( v )
					prop:SetParent( ent )
					self.enttbl[k] = nil

					-- Undo shit
					undo_tbl[prop] = data
				end
			else
				-- Not going to parent, just deselect it
				if IsValid( prop ) then prop:SetColor( v ) end
				self.enttbl[k] = nil
			end
		end

		-- Unparenting function for undo
		undo.AddFunction( function( tab, undo_tbl )
			for prop, data in pairs( undo_tbl ) do
				if IsValid( prop ) then
					local phys = prop:GetPhysicsObject()
					if IsValid( phys ) then
						-- Save some stuff because we want ent values not physobj values
						local pos = prop:GetPos()
						local ang = prop:GetAngles()
						local mat = prop:GetMaterial()
						local col = prop:GetColor()

						-- Unparent
						phys:EnableMotion( false )
						prop:SetParent( nil )

						-- Restore values
						prop:SetColor( col )
						prop:SetMaterial( mat )
						prop:SetAngles( ang )
						prop:SetPos( pos )

						if data.Mass then
							phys:SetMass( data.Mass )
						end
						if data.ColGroup then
							prop:SetCollisionGroup( data.ColGroup )
						end
						if data.DisabledShadow then
							prop:DrawShadow( true )
						end

					end
				end
			end
		end, undo_tbl )
		undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		self.enttbl = {}
	end

	return true
end

function TOOL:Reload()
	if CLIENT then return false end
	if table.Count( self.enttbl ) < 1 then return end

	for k,v in pairs( self.enttbl ) do
		local prop = ents.GetByIndex( k )
		if prop:IsValid() then
			prop:SetColor( v )
			self.enttbl[k] = nil
		end
	end
	self.enttbl = {}
	return true
end