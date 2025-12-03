class USolarFlareSunBlackHolePullCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSun Sun;
	TArray<ABlackHoleDebrisActor> DebrisActors;

	float BlackHolePullRadius = 510000.0;
	float Speed = 10000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sun = Cast<ASolarFlareSun>(Owner);
		DebrisActors = TListedActors<ABlackHoleDebrisActor>().GetArray();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Sun.Phase != ESolarFlareSunPhase::BlackHole)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Sun.Phase != ESolarFlareSunPhase::BlackHole)
			return true;
		
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
		BlackHolePullRadius += Speed * DeltaTime;

		// Debug::DrawDebugSphere(Sun.ActorLocation, BlackHolePullRadius, 25, FLinearColor::Purple, 800.0);

		for (ABlackHoleDebrisActor Debris : DebrisActors)
		{
			if (!Debris.bIsPulling)
			{
				if ((Debris.ActorLocation - Sun.ActorLocation).Size() < BlackHolePullRadius)
					Debris.ActivateBlackolePull(Sun.ActorLocation);
			}
		}
	}
};