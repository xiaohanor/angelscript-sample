class UTeenDragonSprintCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonSprintCamera);
	default CapabilityTags.Add(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAirGlide);
	default CapabilityTags.Add(TeenDragonCapabilityTags::BlockedWhileInTeenDragonClimb);
	default CapabilityTags.Add(TeenDragonCapabilityTags::BlockedWhileInTeenDragonRoll);
	default CapabilityTags.Add(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAcidSpray);
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 160;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTeenDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DragonComp.bIsSprinting)
			return false;

		if (DragonComp.bTopDownMode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DragonComp.bIsSprinting)
			return true;
		
		if (DragonComp.bTopDownMode)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(DragonComp.SprintCameraSettings, 2, this, SubPriority = 54);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}
};