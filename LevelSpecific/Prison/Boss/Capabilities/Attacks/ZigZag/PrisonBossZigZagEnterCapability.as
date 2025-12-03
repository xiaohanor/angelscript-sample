class UPrisonBossZigZagEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector TargetLocation;
	bool bReachedLocation = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::ZigZag)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bReachedLocation && ActiveDuration >= PrisonBoss::ZigZagEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsEnteringZigZag = true;
		bReachedLocation = false;

		TargetLocation = Boss.MiddlePoint.ActorLocation;

		UPrisonBossEffectEventHandler::Trigger_ZigZagEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringZigZag = false;
		Boss.SetActorLocation(TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLocation, DeltaTime, 2000.0);
		Boss.SetActorLocation(Loc);

		if (Loc.Equals(TargetLocation))
			bReachedLocation = true;
	}
}