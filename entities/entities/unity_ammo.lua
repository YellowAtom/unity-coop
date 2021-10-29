AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Ammo Base"
ENT.Category = "Unity"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "AmmoAmount")
	self:NetworkVar("String", 0, "AmmoType")
end

if SERVER then 

	function ENT:Initialize()
		self:SetModel(self:GetModel() != "models/error.mdl" and self:GetModel() or "models/items/boxmrounds.mdl")

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:DrawShadow(true)
		self:SetTrigger(true)

		local physObj = self:GetPhysicsObject()

		if physObj:IsValid() then
			physObj:Wake()
		end
	end

	function ENT:StartTouch( entity )
		if entity:IsPlayer() then
			entity:GiveAmmo(self:GetAmmoAmount(), self:GetAmmoType())

			self:Remove()
		end
	end

	function ENT:PhysicsCollide(data, physObj)
		if (data.Speed > 60 and data.DeltaTime > 0.2) then
			self:EmitSound("Default.ImpactSoft", nil, nil, data.Speed )
		end
	end

else
	function ENT:Draw()
		self:DrawModel()
	end
end
