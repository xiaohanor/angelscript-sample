class UDragonSwordBoomerangReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADragonSwordBoomerang Boomerang;
	UDragonSwordUserComponent PlayerSwordComp;
	TArray<UDragonSwordCombatResponseComponent> HitResponseComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boomerang = Cast<ADragonSwordBoomerang>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boomerang.bIsMovingToInitialTarget)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= DragonSwordBoomerang::RecallMoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerSwordComp = UDragonSwordUserComponent::Get(Boomerang.ReturnPlayerTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto CombatComp = UDragonSwordCombatUserComponent::Get(Boomerang.ReturnPlayerTarget);
		CombatComp.UnblockSword(n"SwordBoomerang");
		Boomerang.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector StartLocation = Boomerang.ActorLocation;
		auto TargetTransform = PlayerSwordComp.Weapon.ActorTransform;
		
		if (HasControl())
		{
			Boomerang.AccLocation.AccelerateTo(TargetTransform.Location, DragonSwordBoomerang::RecallMoveDuration, DeltaTime);
			Boomerang.SyncedLocationComp.Value = Boomerang.AccLocation.Value;
		}
		FRotator NewRotation;
		if (ActiveDuration < DragonSwordBoomerang::RecallMoveDuration * 0.5)
		{
			NewRotation = Boomerang.ActorRotation + FRotator(0, DragonSwordBoomerang::SpinSpeed * DeltaTime, 0);
		}
		else
		{
			FRotator TargetRotation = FRotator::MakeFromZX(-TargetTransform.Rotation.RightVector, TargetTransform.Rotation.UpVector);
			NewRotation = Math::RInterpConstantTo(Boomerang.ActorRotation, TargetRotation, DeltaTime, DragonSwordBoomerang::SpinSpeed);
		}
		FVector NewLocation = Boomerang.SyncedLocationComp.Value;
		Boomerang.SetActorLocationAndRotation(NewLocation, NewRotation);
		if (HasControl())
		{
			Boomerang.TraceForHits(StartLocation, NewLocation, HitResponseComponents);
			if (HitResponseComponents.Num() > 0 && Boomerang.CanDestroyTargets())
				Boomerang.CrumbHandleHits(HitResponseComponents);
		}
	}
};