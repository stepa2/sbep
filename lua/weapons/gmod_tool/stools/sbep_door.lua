TOOL.Category		= "SBEP"
TOOL.Tab 			= "Custom Addon Framework"
TOOL.Name			= "#Door"
TOOL.Command		= nil
TOOL.ConfigName 	= ""

local DoorToolModels = list.Get( "SBEP_DoorToolModels" )

if CLIENT then
	language.Add( "Tool.sbep_door.name"	, "SBEP Door Tool" 				)
	language.Add( "Tool.sbep_door.desc"	, "Create an SBEP door." 		)
	language.Add( "Tool.sbep_door.0"	, "Left click to spawn a door. Right-click a door to cycle through any alternative models." )
	language.Add( "undone_SBEP Door"	, "Undone SBEP Door"			)
end

local CategoryTable = {}
CategoryTable[1] = {
	{ name = "Doors"			, cat = "Door"	 	} ,
	{ name = "Hatches (Base)" 	, cat = "Hatch_B"	} ,
	{ name = "Hatches (Mid)" 	, cat = "Hatch_M"	} ,
	{ name = "Hatches (Top)"	, cat = "Hatch_T"	} ,
	{ name = "Other"			, cat = "Other"	 	}
					}

CategoryTable[2] = {
	{ name = "ModBridge Doors"	, cat = "Modbridge" , model = "models/cerus/modbridge/misc/doors/door11a.mdl" 	 }
					}

TOOL.ClientConVar[ "skin"  		] = 0
TOOL.ClientConVar[ "model"  	] = "models/smallbridge/panels/sbpaneldoor.mdl"
TOOL.ClientConVar[ "wire"  		] = 1
TOOL.ClientConVar[ "enableuse"	] = 1

if ( SERVER ) then

	function MakeDoorController( Player, Data )

		local DoorController = ents.Create( "sbep_base_door_controller" )
		duplicator.DoGeneric( DoorController, Data )
		DoorController:Spawn()

		duplicator.DoGenericPhysics( DoorController, Player, Data )

		return DoorController

	end

	duplicator.RegisterEntityClass( "sbep_base_door_controller", MakeDoorController, "Data" )
end

function TOOL:LeftClick( tr )

	if CLIENT then return end

	local ply = self:GetOwner()

	if ply:GetInfoNum( "sbep_door_wire", 1 ) == 0 and ply:GetInfoNum( "sbep_door_enableuse", 1 ) == 0 then
		ply:AddHint("Cannot be both unusable and unwireable.", NOTIFY_ERROR, 4)
		return
	end

	local model = self:GetClientInfo( "model" )
	local pos = tr.HitPos

	local DoorController = ents.Create( "sbep_base_door_controller" )
	DoorController:SetModel( model )
	DoorController:SetSkin( ply:GetInfoNum( "sbep_door_skin", 0 ) )

	DoorController:SetUsable( ply:GetInfoNum( "sbep_door_enableuse", 1 ) == 1 )

	DoorController:Spawn()
	DoorController:Activate()

	DoorController:SetPos( pos - Vector(0,0, DoorController:OBBMins().z ) )

	if CPPI then DoorController:CPPISetOwner(ply) end
	DoorController:AddDoors()

	DoorController:MakeWire( ply:GetInfoNum( "sbep_door_wire", 1 ) == 1 )

	undo.Create("SBEP Door")
		undo.AddEntity( DoorController )
		if DoorController.DT then
			for _,door in ipairs( DoorController.DT ) do
				undo.AddEntity( door )
			end
		end
		undo.SetPlayer( ply )
	undo.Finish()

	return true
end

function TOOL:RightClick( tr )

	if CLIENT then return end
	if !tr.Hit or !tr.Entity or !tr.Entity:IsValid() then return end
	local door = tr.Entity
	local entclass = door:GetClass()

	if entclass == "sbep_base_door" then
		class = door:GetDoorClass()
		door:SetDoorClass( class + 1 )

		return true
	end
end

function TOOL:Reload( tr )

end

function TOOL.BuildCPanel( panel )
	panel:SetSpacing( 10 )
	panel:SetName( "SBEP Door" )

	local WireCheckBox = vgui.Create( "DCheckBoxLabel", panel )
	WireCheckBox:Dock(TOP)
	WireCheckBox:SetText( "Create Wire Inputs:" )
	WireCheckBox:SetTextColor(Color(0,0,0,255))
	WireCheckBox:SetConVar( "sbep_door_wire" )
	WireCheckBox:SetValue( GetConVar( "sbep_door_wire" ):GetBool() )

	local UseCheckBox = vgui.Create( "DCheckBoxLabel", panel )
	UseCheckBox:Dock(TOP)
	UseCheckBox:SetText( "Enable Use Key:" )
	UseCheckBox:SetTextColor(Color(0,0,0,255))
	UseCheckBox:SetConVar( "sbep_door_enableuse" )
	UseCheckBox:SetValue( GetConVar( "sbep_door_enableuse" ):GetBool()  )

	for Tab,v in pairs( DoorToolModels ) do
		for Category, models in pairs( v ) do
			local catPanel = vgui.Create( "DCollapsibleCategory", panel )
			catPanel:Dock( TOP )
			catPanel:DockMargin(2,2,2,2)
			catPanel:SetText(Category)
			catPanel:SetLabel(Category)

			local grid = vgui.Create( "DGrid", catPanel )
			grid:Dock( TOP )

			grid:SetColWide( 64 )
			grid:SetRowHeight( 64 )

			for key, modelpath in pairs( models ) do
				local icon = vgui.Create( "SpawnIcon", panel )
				icon:SetModel( modelpath )
				icon:SetTooltip( modelpath )
				icon.DoClick = function()
					RunConsoleCommand( "sbep_door_model", modelpath )
				end
				grid:AddItem( icon )

			end
			catPanel:SetExpanded( 0 )
		end
	end

end
