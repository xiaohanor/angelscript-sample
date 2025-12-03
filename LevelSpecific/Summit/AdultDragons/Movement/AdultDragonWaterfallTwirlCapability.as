class UAdultDragonWaterfallTwirlCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 130;
	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;

	float TotalRollAmount;
	float SpinSpeed;
	float CurrentRollAmount;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DragonComp.bIsTwirling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= DragonComp.TwirlDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TotalRollAmount = DragonComp.NrOfTwirlSpins * 360;
		SpinSpeed = TotalRollAmount / DragonComp.TwirlDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AdultDragon.RootComponent.RelativeRotation = FRotator::ZeroRotator;
		DragonComp.bIsTwirling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DragonComp.AnimParams.Pitching = 0;
		CurrentRollAmount += SpinSpeed * DeltaTime;
		CurrentRollAmount = Math::Clamp(CurrentRollAmount, 0, TotalRollAmount);
		DragonComp.AdultDragon.RootComponent.RelativeRotation = (FRotator(0, 0, CurrentRollAmount));
		// DragonComp.AnimParams.Pitching = Math::FInterpTo(DragonComp.AnimParams.Pitching, 1, DeltaTime, 1.0);
		// DragonComp.AnimParams.Banking = Math::FInterpTo(DragonComp.AnimParams.Banking, 0, DeltaTime, 1.0);
	}
};