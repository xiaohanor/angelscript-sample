class UAcidStatueCountdownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AAcidStatue Statue;
	FRotator StartRelativeRotation;
	bool bSwitchOn;
	float SinTime;
	bool bAlmostFinished;

	FVector StatueRelativeOffset = FVector(0,0,-525);
	FVector StatueRelativeStart;
	FHazeAcceleratedVector AccelVector;

	float LowerDelay = 1.0;
	float CurrentActiveDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Statue = Cast<AAcidStatue>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Statue.bStatueActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentActiveDuration > Statue.Duration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SinTime = 0;
		Statue.ActivateStatue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bAlmostFinished = false;
		Statue.DeactivateStatue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentActiveDuration = ActiveDuration - LowerDelay;
		CurrentActiveDuration = Math::Clamp(CurrentActiveDuration, 0, 100);

		float Alpha = CurrentActiveDuration / Statue.Duration;
		FVector TargetLocation = Math::Lerp(StatueRelativeStart, StatueRelativeOffset, Alpha);
		AccelVector.AccelerateTo(TargetLocation, Statue.Duration / Statue.Duration, DeltaTime);

		if (ActiveDuration > Statue.Duration - Statue.AlmostFinishedDuration)
		{
			SinTime += DeltaTime;

			float Sin = Math::Sin(SinTime * 35);


			if (Sin > 0 && bSwitchOn)
			{
				// Statue.FlashMaterialOn();
				bSwitchOn = false;
			}
			else if (Sin < 0 && !bSwitchOn)
			{
				bSwitchOn = true;
				// Statue.FlashMaterialOff();
			}

			if (!bAlmostFinished)
			{
				bAlmostFinished = true;
				Statue.OnCraftTempleAcidStatueAlmostFinished.Broadcast();
			}
		}
	}
};