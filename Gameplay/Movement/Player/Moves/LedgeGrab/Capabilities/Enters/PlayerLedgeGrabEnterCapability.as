class UPlayerLedgeGrabEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabEnter);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 0;

	UPlayerMovementComponent MoveComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeGrabData& LedgeGrabActivationData) const
	{
		if(PlayerLedgeMantle::CVar_EnableLedgeMantle.GetInt() == 1 && !LedgeGrabComp.bSnowMonkeyLedgeGrabActivated)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (LedgeGrabComp.Data.HasValidData())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		FPlayerLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrab(Player, Player.ActorForwardVector, LedgeGrabData, this, IsDebugActive()))
			return false;

		if (!LedgeGrabData.TopHitComponent.HasTag(n"LedgeGrabbable"))
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