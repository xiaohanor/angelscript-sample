class UMimicChestReturnToStartCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMimic Mimic;
	bool bFinishedTurn;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mimic = Cast<AMoonMarketMimic>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Mimic.bEatingACat)
			return false;

		if (!Mimic.bFinishLaunch)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mimic.bEatingACat)
			return true;
		
		if (bFinishedTurn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bFinishedTurn = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mimic.FinishReturnToStart();
		Mimic.bFinishLaunch = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Mimic.ActorRotation = Math::RInterpConstantTo(Mimic.ActorRotation, Mimic.StartRot, DeltaTime, 180.0);
		
		if (Mimic.ActorRotation.Equals(Mimic.StartRot, 1.0))
		{
			bFinishedTurn = true;
		}
	}
};