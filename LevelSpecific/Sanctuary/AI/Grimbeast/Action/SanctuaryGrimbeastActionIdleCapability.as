struct FSanctuaryGrimbeastActionIdleData
{
	float Duration;
	bool bRotateTowardsPlayers = true;
}

class USanctuaryGrimbeastActionIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryGrimbeastActionIdleData Params;
	default CapabilityTags.Add(GrimbeastTags::Grimbeast);
	default CapabilityTags.Add(GrimbeastTags::Action);
	USanctuaryGrimbeastActionsComponent ActionComp;

	FHazeAcceleratedRotator AccRotation;

	AAISanctuaryGrimbeast Grimbeast;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Grimbeast = Cast<AAISanctuaryGrimbeast>(Owner);
		ActionComp = USanctuaryGrimbeastActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryGrimbeastActionIdleData& ActivationParams) const
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
	void OnActivated(FSanctuaryGrimbeastActionIdleData ActivationParams)
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
			Grimbeast.Mesh.SetWorldRotation(AccRotation.Value);
		}
	}
}
