class UPlayerLedgeGrabEnterWallRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabEnter);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 2;

	UPlayerMovementComponent MoveComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;
	UPlayerWallRunComponent WallRunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeGrabData& LedgeGrabActivationData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (LedgeGrabComp.Data.HasValidData())
			return false;

		if (!WallRunComp.HasActiveWallRun())
			return false;
	
		FPlayerLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrab(Player, -WallRunComp.ActiveData.WallNormal, LedgeGrabData, this, IsDebugActive()))
			return false;

		if (LedgeGrabData.bFeetPlanted)
			return false;	
		
		LedgeGrabActivationData = LedgeGrabData;
  		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLedgeGrabData LedgeGrabActivationData)
	{
		LedgeGrabComp.Data = LedgeGrabActivationData;
	}
}