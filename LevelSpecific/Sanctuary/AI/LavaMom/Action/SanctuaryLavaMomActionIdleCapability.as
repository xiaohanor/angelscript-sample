struct FSanctuaryLavaMomActionIdleData
{
	float Duration;
	bool bRotateTowardsPlayers = true;
}

class USanctuaryLavaMomActionIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavaMomActionIdleData Params;
	default CapabilityTags.Add(LavaMomTags::LavaMom);
	default CapabilityTags.Add(LavaMomTags::Action);
	USanctuaryLavaMomActionsComponent ActionComp;

	FHazeAcceleratedRotator AccRotation;
	ASanctuaryLavaMom LavaMom;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaMom = Cast<ASanctuaryLavaMom>(Owner);
		ActionComp = USanctuaryLavaMomActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLavaMomActionIdleData& ActivationParams) const
	{
		if (ActionComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ActionComp.ActionQueue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLavaMomActionIdleData ActivationParams)
	{
		Params = ActivationParams;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Params.bRotateTowardsPlayers)
		{
			FVector MioLocation = Game::Mio.ActorLocation;
			FVector ZoeLocation = Game::Zoe.ActorLocation;
			FVector BetweenMioZoe = MioLocation + (ZoeLocation - MioLocation) * 0.5;
			FVector TowardsMioZoe = BetweenMioZoe - Owner.ActorLocation;
			FRotator TargetRotation = FRotator::MakeFromXZ(TowardsMioZoe.GetSafeNormal(), FVector::UpVector);
			AccRotation.AccelerateTo(TargetRotation, 1.5, DeltaTime);
			LavaMom.SetActorRotation(AccRotation.Value);
		}
	}
}
