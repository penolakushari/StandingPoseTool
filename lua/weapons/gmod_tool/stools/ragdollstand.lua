if SERVER then
util.AddNetworkString("StandPose_Server")
util.AddNetworkString("StandPoser_Client")

net.Receive("StandPose_Server", function() 
	local rag = net.ReadEntity()
	local ent = net.ReadEntity()

	for i=0,rag:GetPhysicsObjectCount()-1 do
		local phys = rag:GetPhysicsObjectNum(i)
		local b = rag:TranslatePhysBoneToBone(i)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		phys:EnableMotion(true)
		phys:Wake()
		phys:SetPos(pos)
		phys:SetAngles(ang)
--		if string.sub(rag:GetBoneName(b),1,4) == "prp_" then
--			phys:EnableMotion(true)
--			phys:Wake()
--		else
			phys:EnableMotion(false)
			phys:Wake()
--		end
	end
	ent:Remove()
end)

end


TOOL.Category		= "Poser"
TOOL.Name			= "Stand Pose"
TOOL.Command		= nil
TOOL.ConfigName		= nil

function TOOL:LeftClick(tr)
	if self:GetStage() == 0 then
	
	if !IsValid(tr.Entity) then return false end
	if tr.Entity:GetClass() != "prop_ragdoll" then return false end
	
	if CLIENT then return true end
	
	self.SelectedEnt = tr.Entity
	self:SetStage(1)
	return true
	
	else
	
	local rag = self.SelectedEnt
	if !IsValid(rag) then
		self:SetStage(0)
		return true
	end
	
	
	
	local ent = ents.Create("prop_dynamic")
	ent:SetModel(rag:GetModel())
	ent:SetPos(tr.HitPos)
	local angle = (tr.HitPos - self:GetOwner():GetPos()):Angle()
	ent:SetAngles(Angle(0,angle.y-180,0))
	ent:Spawn()
	
	if CLIENT then return true end
	local PhysObjects = rag:GetPhysicsObjectCount()-1
	
	timer.Simple(0.1, function()
		net.Start("StandPoser_Client")
		net.WriteEntity(rag)
		net.WriteEntity(ent)
		net.WriteInt(PhysObjects, 8)
		net.Send(self:GetOwner())
	end)
	self:SetStage(0)
	return true
	
	end
end

function TOOL:RightClick(tr)
	if self:GetStage() == 1 then
		self:SetStage(0)
		return true
	end
	return false
end

if CLIENT then

net.Receive("StandPoser_Client", function() 
	local rag = net.ReadEntity()
	local ent = net.ReadEntity()
	local PhysObjects = net.ReadInt(8)
	
	net.Start("StandPose_Server")
	net.WriteEntity(rag)
	net.WriteEntity(ent)
	for i=0,PhysObjects do
		local phys = rag:GetPhysicsObjectNum(i)
		local b = rag:TranslatePhysBoneToBone(i)
		local pos,ang = ent:GetBonePosition(b)
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


language.Add("tool.ragdollstand.name","Stand Pose")
language.Add("tool.ragdollstand.desc","Position ragdolls in a standing pose.")
language.Add("tool.ragdollstand.0","Left Click to select a ragdoll.")
language.Add("tool.ragdollstand.1","Now click on a position where you want the ragdoll to stand or Right Click to cancel.")

end