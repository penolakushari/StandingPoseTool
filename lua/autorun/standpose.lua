if game.SinglePlayer() then

	if SERVER then

	util.AddNetworkString("StandPose_Server")
	util.AddNetworkString("StandPoser_Client")

	net.Receive("StandPose_Server", function() 
		local rag = net.ReadEntity()
		local ent = net.ReadEntity()
		if (rag == ent) or not IsValid(rag) or not IsValid(ent) then return end
		if rag:GetClass() ~= "prop_ragdoll" or ent:GetClass() ~= "prop_dynamic" then return end

		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local phys = rag:GetPhysicsObjectNum(i)
			local b = rag:TranslatePhysBoneToBone(i)
			local pos = net.ReadVector()
			local ang = net.ReadAngle()
			phys:EnableMotion(true)
			phys:Wake()
			phys:SetPos(pos)
			phys:SetAngles(ang)
			phys:EnableMotion(false)
			phys:Wake()

		end
		ent:Remove()
	end)

	end

	if CLIENT then

	net.Receive("StandPoser_Client", function() 
		local rag = net.ReadEntity()
		local ent = net.ReadEntity()
		local PhysObjects = net.ReadInt(8)

		net.Start("StandPose_Server")
		net.WriteEntity(rag)
		net.WriteEntity(ent)
		for i = 0, PhysObjects do
			local phys = rag:GetPhysicsObjectNum(i)
			local b = rag:TranslatePhysBoneToBone(i)
			local pos, ang = ent:GetBonePosition(b)
			if pos == ent:GetPos() then
				local matrix = ent:GetBoneMatrix(b)
				if matrix then
					pos = matrix:GetTranslation()
					ang = matrix:GetAngles()
				end
			end
			net.WriteVector(pos)
			net.WriteAngle(ang)
		end
		net.SendToServer()
	end)

	end

end

local propt = {}

propt.MenuLabel = "Stand Pose"
propt.Order = 5000

propt.Filter = function( self, ent )
	if ( !IsValid( ent ) ) then return false end
	if ( ent:GetClass() != "prop_ragdoll" ) then return false end
	return true 
end

propt.Action = function( self, ent )
	self:MsgStart()
	net.WriteEntity( ent )
	self:MsgEnd()
end

propt.Receive = function( self, length, player )

	local rag = net.ReadEntity()
	
	if ( !IsValid( rag ) ) then return end
	if ( !IsValid( player ) ) then return end
	if ( rag:GetClass() != "prop_ragdoll" ) then return end

	local ragpos = rag:GetPos()
	if not rag:IsInWorld() then
		local _, max = rag:WorldSpaceAABB()
		ragpos.z = max.z
	end

	local tr = util.TraceLine({start = ragpos, endpos = ragpos - Vector(0, 0, 3000), filter = rag})
	if not util.IsInWorld(tr.HitPos) then
		tr = util.TraceLine({start = player:EyePos(), endpos = ragpos, filter = {rag, player}})
	end

	local hpos = tr.HitPos
	local ent = ents.Create("prop_dynamic")
	ent:SetModel(rag:GetModel())
	ent:SetPos(hpos)
	local min, max = ent:WorldSpaceAABB()
	local diff = hpos.z - min.z
	local low = Vector(hpos.x, hpos.y, min.z)
	if not util.IsInWorld(low) then
		low.z = low.z + (max.z - min.z) * 0.1
		if not util.IsInWorld(low) then
			ent:SetPos(hpos + Vector(0, 0, diff))
		end
	end
	local angle = (hpos - player:GetPos()):Angle()
	ent:SetAngles(Angle(0, angle.y - 180, 0))
	ent:Spawn()

	if CLIENT then return true end
	local PhysObjects = rag:GetPhysicsObjectCount() - 1
	
	if game.SinglePlayer() then
		timer.Simple(0.1, function()
			net.Start("StandPoser_Client")
			net.WriteEntity(rag)
			net.WriteEntity(ent)
			net.WriteInt(PhysObjects, 8)
			net.Send(player)
		end)
	else -- if we're in multiplayer, we revert back to the old way stand pose worked, otherwise stuff will get weird
		for i = 0, PhysObjects do
			local phys = rag:GetPhysicsObjectNum(i)
			local b = rag:TranslatePhysBoneToBone(i)
			local pos, ang = ent:GetBonePosition(b)
			phys:EnableMotion(true)
			phys:Wake()
			phys:SetPos(pos)
			phys:SetAngles(ang)
			if string.sub(rag:GetBoneName(b), 1, 4) == "prp_" then
				phys:EnableMotion(true)
				phys:Wake()
			else
				phys:EnableMotion(false)
				phys:Wake()
			end
		end
	ent:Remove()
	end
	
end	

properties.Add("standpose", propt)
