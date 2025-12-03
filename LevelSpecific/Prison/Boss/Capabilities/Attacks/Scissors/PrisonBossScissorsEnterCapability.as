class UPrisonBossScissorsEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector TargetLocation;
	FRotator TargetRotation;
	bool bReachedTarget = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::Scissors)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bReachedTarget && ActiveDuration >= PrisonBoss::ScissorsEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedTarget = false;

		Boss.AnimationData.bIsEnteringScissors = true;
		
		TargetLocation = Boss.MiddlePoint.ActorLocation;

		AActor TargetActor = Boss.Platforms[0];
		for (AActor Actor : Boss.Platforms)
		{
			float Dist = Game::Zoe.GetDistanceTo(Actor);
			if (TargetActor.GetDistanceTo(Game::Zoe) > Dist)
				TargetActor = Actor;
		}

		TargetRotation = (TargetActor.ActorLocation - Boss.MiddlePoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

		Boss.TriggerInactiveDangerZones();

		UPrisonBossEffectEventHandler::Trigger_ScissorsEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringScissors = false;
		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLocation, DeltaTime, 2400.0);
		Boss.SetActorLocation(Loc);

		AActor TargetActor = Boss.Platforms[0];
		for (AActor Actor : Boss.Platforms)
		{
			float Dist = Game::Zoe.GetDistanceTo(Actor);
			if (TargetActor.GetDistanceTo(Game::Zoe) > Dist)
				TargetActor = Actor;
		}

		TargetRotation = (TargetActor.ActorLocation - Boss.MiddlePoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);

		if (Loc.Equals(TargetLocation))
			bReachedTarget = true;
	}
}