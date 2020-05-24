TOOL.Category		= "Constraints"
TOOL.Name			= "#tool.multi_unparent.listname"
TOOL.Command		= nil
TOOL.ConfigName		= ""

local plytbl = {}

if CLIENT then
	language.Add( "tool.multi_unparent.name", "Multi-Unparent Tool" )
	language.Add( "tool.multi_unparent.listname", "Multi-Unparent" )
	language.Add( "tool.multi_unparent.desc", "Unparents multiple props." )

	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Select an entity to be unparented" },
		{ name = "right_0", stage = 0, text = "Unparent selected entities" },
		{ name = "left_use_0", stage = 0, text = "Select everything in the area", icon2 = "gui/e.png"},
		{ name = "left_shift_0", stage = 0, text = "Select the children of the target entity", icon2 = "gui/sprint.png"},
		{ name = "reload_0", stage = 0, text = "De-select all entities"},
	}

	for _, V in pairs(TOOL.Information) do
		language.Add("Tool.multi_unparent." .. V.name, V.text)
	end

	local function Select() -- runs a trace on the client rather than the server so that it will reliably hit parented entities
		local tr = util.TraceLine( util.GetPlayerTrace(LocalPlayer()) )

		net.Start("unparent_select")
			net.WriteEntity(tr.Entity)
			net.WriteVector(tr.HitPos)
			net.WriteUInt(net.ReadUInt(10), 10)
		net.SendToServer()
	end
	net.Receive( "unparent_select", Select )
end

if SERVER then
	util.AddNetworkString("unparent_select")

	local function Select( ply, ent )
		local eid = ent:EntIndex()

		if not IsValid( ent ) or ent:IsWorld() or ent:IsPlayer() then return end
		local uid = ply:UserID()

		plytbl[uid] = plytbl[uid] or {}
		local enttbl = plytbl[ply:UserID()] or {}

		if not enttbl[eid] then
			local col = Color(0, 0, 0, 0)
			col = ent:GetColor()
			enttbl[eid] = col
			ent:SetColor( Color(255, 0, 0, 100) )
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		else
			local col = enttbl[eid]
			ent:SetColor( col )
			enttbl[eid] = nil
		end
	end

	local function IsPropOwner( ply, ent )
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

	net.Receive("unparent_select", function(_, Ply)
		local Ent = net.ReadEntity()
		local Pos = net.ReadVector()
		local Radius = net.ReadUInt(10)

		if not IsValid(Ent) then return end
		if not IsPropOwner(Ply, Ent) then return end
		if Ply:KeyDown(IN_SPEED) then -- Select family
			local SelectedProps = 0
			local Children = Ent:GetChildren()
				Children[Ent] = Ent

			for k, v in pairs( Children ) do
				if IsValid(v) and not plytbl[v:EntIndex()] and IsPropOwner( Ply, v ) then
					Select(Ply, v)
					SelectedProps = SelectedProps + 1
				end
			end

			Ply:PrintMessage( HUD_PRINTTALK, "Multi-Unparent: " .. SelectedProps .. " props were selected." )
		elseif Ply:KeyDown(IN_USE) then -- Select in radius
			local SelectedProps = 0

			for k, v in pairs( ents.FindInSphere( Pos, Radius ) ) do
				if IsValid(v) and not plytbl[v:EntIndex()] and IsPropOwner( Ply, v ) then
					Select(Ply, v)
					SelectedProps = SelectedProps + 1
				end
			end

			Ply:PrintMessage( HUD_PRINTTALK, "Multi-Unparent: " .. SelectedProps .. " props were selected." )
		else
			Select(Ply, Ent)
		end
	end)
end

TOOL.ClientConVar["radius"] = "512"

function TOOL.BuildCPanel( panel )
	panel:AddControl("Slider", {
		Label = "Auto Select Radius:",
		Type = "integer",
		Min = "64",
		Max = "1024",
		Command = "multi_unparent_radius"
	} )
end

function TOOL:LeftClick( Trace )
	local Ent = Trace.Entity

	if not IsValid(Ent) then return false end
	if Ent:IsWorld() then return false end

	if CLIENT then return true end

	net.Start("unparent_select")
		net.WriteUInt(math.Clamp(self:GetClientNumber("Radius"), 64, 1024), 10)
	net.Send(self:GetOwner())

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end

	local uid = self:GetOwner():UserID()
	local enttbl = plytbl[uid]

	if (not enttbl) or table.Count( enttbl ) < 1 then return false end

	for k, v in pairs( enttbl ) do
		local prop = Entity( k )
		if IsValid( prop ) then
			local phys = prop:GetPhysicsObject()
			if IsValid( phys ) then
				if IsValid( prop:GetParent() ) then -- don't unparent if ent is not parented

					-- Save some stuff because we want ent values not physobj values
					local pos = prop:GetPos()
					local ang = prop:GetAngles()
					local mat = prop:GetMaterial()
					local mass = phys:GetMass()

					-- Unparent
					phys:EnableMotion( false )
					prop:SetParent( nil )

					-- Restore values
					phys:SetMass( mass )
					prop:SetMaterial( mat )
					prop:SetAngles( ang )
					prop:SetPos( pos )
				end

				-- Deselect ent
				prop:SetColor( v )
				enttbl[k] = nil
			end
		end
	end
	enttbl = {}
	return true
end

function TOOL:Reload()
	if CLIENT then return false end
	local uid = self:GetOwner():UserID()
	local enttbl = plytbl[uid]
	if (not enttbl) or table.Count( enttbl ) < 1 then return false end

	for k,v in pairs( enttbl ) do
		local prop = ents.GetByIndex( k )
		if prop:IsValid() then
			prop:SetColor( v )
			enttbl[k] = nil
		end
	end
	enttbl = {}
	return true
end