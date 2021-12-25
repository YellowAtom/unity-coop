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
	self:NetworkVar("Bool", 0, "AmmoSpent")
	self:SetAmmoSpent( false )
end

if SERVER then 

	function ENT:Initialize()
		self:SetModel(self:GetModel() != "models/error.mdl" and self:GetModel() or "models/items/boxmrounds.mdl")

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		self:DrawShadow( true )
		self:SetTrigger( true )

		local physObj = self:GetPhysicsObject()

		if physObj:IsValid() then
			physObj:Wake()
		end
	end

	function ENT:Touch( entity )
		if entity:IsPlayer() and hook.Run("PlayerCanPickupItem", entity, self) and not self:GetAmmoSpent() then
			entity.touchingUnityAmmo = true

			local ammoAmount = self:GetAmmoAmount()
			local ammoType = self:GetAmmoType()
			local dif = entity:GetAmmoCount(ammoType) + ammoAmount - game.GetAmmoMax(game.GetAmmoID(ammoType))

			if dif >= 0 then
				if dif == ammoAmount then
					return
				end

				entity:GiveAmmo(ammoAmount - dif, ammoType)

				self:SetAmmoAmount(dif)

				if dif == 0 then
					self:SetAmmoSpent( true )
					self:Remove()
				end

				return
			end

			entity:GiveAmmo(ammoAmount, ammoType)

			self:SetAmmoSpent( true )
			self:Remove()
		end
	end

	function ENT:EndTouch( entity )
		entity.touchingUnityAmmo = false
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
