class USanctuaryBoatImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(SanctuaryBoatTags::Boat);
	default CapabilityTags.Add(SanctuaryBoatTags::BoatImpact);
	
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBoat Boat;

	UHazeMovementComponent MoveComp;

	float ImpactEventThresholdSpeed = 0.0;
	float ImpactEventCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Boat = Cast<ASanctuaryBoat>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < ImpactEventCooldown)
			return false;

		if (!MoveComp.HasAnyValidBlockingImpacts())
			return false;

		if (MoveComp.PreviousVelocity.Size() < ImpactEventThresholdSpeed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto HitResult = MoveComp.AllImpacts[0];
		FSanctuaryBoatImpactEventData ImpactEventData;
		ImpactEventData.ImpactStrength = MoveComp.PreviousVelocity.Size();

		USanctuaryBoatEventHandler::Trigger_Impact(Owner, ImpactEventData);

		if(ImpactEventData.ImpactStrength > 90)
			Boat.ActivateForceFeedBack();
		
		if(ImpactEventData.ImpactStrength > 300)
			Boat.ActivateForceFeedBackAndCameraShake();
		
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