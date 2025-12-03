class UDragonSwordBoomerangThrowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADragonSwordBoomerang Boomerang;
	TArray<UDragonSwordCombatResponseComponent> HitResponseComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boomerang = Cast<ADragonSwordBoomerang>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boomerang.bIsMovingToInitialTarget)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boomerang.bIsMovingToInitialTarget)
			return true;

		if (Boomerang.bAutoRecallAfterDuration && ActiveDuration > DragonSwordBoomerang::ThrowMoveDuration + DragonSwordBoomerang::StayInPlaceDuration)
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
		Boomerang.bIsMovingToInitialTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector StartLocation = Boomerang.ActorLocation;
		if (HasControl())
		{
			if (!Boomerang.bIsStoppedInPlace)
			{
				FVector TargetLocation = Boomerang.InitialTargetLocation;
				Boomerang.AccLocation.AccelerateTo(TargetLocation, DragonSwordBoomerang::ThrowMoveDuration, DeltaTime);
				Boomerang.SyncedLocationComp.Value = Boomerang.AccLocation.Value;
			}
		}

		FVector NewLocation = Boomerang.SyncedLocationComp.Value;
		FRotator SpinRotation = FRotator(90, DragonSwordBoomerang::SpinSpeed * ActiveDuration, 0);
		Boomerang.SetActorLocationAndRotation(NewLocation, SpinRotation);

		if (HasControl())
		{
			Boomerang.TraceForHits(StartLocation, NewLocation, HitResponseComponents);
			if (HitResponseComponents.Num() > 0 && Boomerang.CanDestroyTargets())
			{
				Boomerang.CrumbHandleHits(HitResponseComponents);
			}
		}
	}
};