class USnowMonkeyLedgeGrabEnterCapability : UHazePlayerCapability
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
	USnowMonkeyLedgeGrabComponent LedgeGrabComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LedgeGrabComp = USnowMonkeyLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSnowMonkeyLedgeGrabData& LedgeGrabActivationData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (LedgeGrabComp.Data.HasValidData())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		FSnowMonkeyLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrab(Player, Player.ActorForwardVector, LedgeGrabData, IsDebugActive()))
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
	void OnActivated(FSnowMonkeyLedgeGrabData LedgeGrabActivationData)
	{
		LedgeGrabComp.Data = LedgeGrabActivationData;
	}
}