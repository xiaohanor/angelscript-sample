class ULightSeekerMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightSeekerMovement");

	ALightSeeker LightSeeker;
	ULightSeekerTargetingComponent TargetingComp;

	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LightSeeker.bIsSleeping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LightSeeker.bIsSleeping)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (LightSeeker.bDebugging)
		{
			PrintToScreen("Moving");
			FLinearColor SphereColor;
			if (LightSeeker.bIsChasing)
				SphereColor = FLinearColor::Yellow;
			
			if (LightSeeker.bIsInTrance)
				SphereColor = FLinearColor::Blue;
			
			if (LightSeeker.bIsReturning)
				SphereColor = FLinearColor::Green;

			// Debug::DrawDebugSphere(TargetingComp.DesiredHeadLocation, 200, 12, SphereColor);
			// Debug::DrawDebugLine(TargetingComp.DesiredHeadLocation, LightSeeker.Head.WorldLocation, FLinearColor::DPink);
		}

		FVector HeadToDesired = TargetingComp.SyncedDesiredHeadLocation.Value - LightSeeker.Head.WorldLocation;

		float CloseSlowDownMultiplier = 1.0;
		if (LightSeeker.SlowDownRange > 0.0 && HeadToDesired.Size() < LightSeeker.SlowDownRange && LightSeeker.Head.ForwardVector.DotProduct(HeadToDesired) > 0.0)
			CloseSlowDownMultiplier = HeadToDesired.Size() / LightSeeker.SlowDownRange;

		float SpeedyBackwardsMultiplier = 1.0;
		if (LightSeeker.Head.ForwardVector.DotProduct(HeadToDesired) < 0.0) // bird is moving towards head, back back quickly!
		{
			if (LightSeeker.bIsChasing)
				SpeedyBackwardsMultiplier = 5.0;
			if (LightSeeker.bIsInTrance)
				SpeedyBackwardsMultiplier = 2.0;
		}

		float MovementLength = GetMovementSpeed() * DeltaTime * CloseSlowDownMultiplier * SpeedyBackwardsMultiplier;
		if (HeadToDesired.Size() > SMALL_NUMBER && HeadToDesired.Size() < MovementLength)
			MovementLength = HeadToDesired.Size();

		FVector DeltaMovement = HeadToDesired.GetSafeNormal() * MovementLength;
		FVector NewRelativeLocation = (LightSeeker.Head.WorldLocation - LightSeeker.Origin.WorldLocation) + DeltaMovement; 
		FVector NewDesiredLocation = NewRelativeLocation.GetClampedToMaxSize(LightSeeker.MaximumReach);

		LightSeeker.Head.SetWorldLocation(LightSeeker.Origin.WorldLocation + NewDesiredLocation);

		LightSeeker.bIsConstrained = NewRelativeLocation.Size() > LightSeeker.MaximumReach;
	}

	private float GetMovementSpeed() const
	{
		if (LightSeeker.bIsChasing)
			return LightSeeker.ChaseSpeed * TargetingComp.ChaseSpeedBoost;

		if (LightSeeker.bIsInTrance)
			return LightSeeker.TranceSpeed;

		return LightSeeker.ReturnSpeed;
	}
}