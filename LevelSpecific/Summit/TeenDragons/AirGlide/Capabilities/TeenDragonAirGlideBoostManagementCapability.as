class UTeenDragonAirGlideBoostManagementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::AfterPhysics;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTeenDragonAirGlideComponent AirGlideComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Recover the air boost when grounded
		if (MoveComp.IsOnWalkableGround())
			AirGlideComp.bInitialAirBoostAvailable = true;

		// Remove air boost when inside an air current
		if (AirGlideComp.bInAirCurrent && !MoveComp.IsOnWalkableGround())
			AirGlideComp.bInitialAirBoostAvailable = false;
		
		if(AirGlideComp.bInitialAirBoostAvailable)
			TEMPORAL_LOG(Player, "Air Glide").Status("Initial air boost available", FLinearColor::Green);
		else
			TEMPORAL_LOG(Player, "Air Glide").Status("Initial air boost not available", FLinearColor::Red);
	}
}