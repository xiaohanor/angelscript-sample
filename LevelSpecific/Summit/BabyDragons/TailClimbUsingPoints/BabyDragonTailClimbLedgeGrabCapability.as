
class UBabyDragonTailClimbLedgeGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 9;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeGrabData& LedgeGrabActivationData) const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return false;
		if (DragonComp.ClimbActivePoint == nullptr)
			return false;
		if (!DragonComp.ClimbActivePoint.bTransitionToLedgeGrab)
			return false;

		FPlayerLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrab(Player, Player.ActorForwardVector, LedgeGrabData, this, IsDebugActive()))
			return false;
		
		LedgeGrabActivationData = LedgeGrabData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLedgeGrabData LedgeGrabActivationData)
	{
		LedgeGrabComp.Data = LedgeGrabActivationData;
		DragonComp.ClimbState = ETailBabyDragonClimbState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};