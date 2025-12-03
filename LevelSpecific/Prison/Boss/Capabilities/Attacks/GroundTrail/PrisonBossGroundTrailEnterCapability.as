class UPrisonBossGroundTrailEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector StartLocation;
	FVector TargetLocation;
	FRotator TargetRotation;

	UDecalComponent TelegraphDecalComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::GroundTrail)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::GroundTrailSlamDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Boss.ActorLocation;

		FVector DirToStart = (StartLocation - TargetLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FVector DirToMid = -DirToStart;
		DirToMid = DirToMid.ConstrainToPlane(FVector::UpVector);
		TargetRotation = DirToMid.Rotation();

		TargetLocation = Boss.MiddlePoint.ActorLocation;
		Boss.AnimationData.bIsEnteringGroundTrail = true;

		TelegraphDecalComp = Decal::SpawnDecalAtLocation(AttackDataComp.GroundTrailSlamDecalMaterial, FVector(100.0, 800.0, 800.0), TargetLocation);
		TelegraphDecalComp.SetWorldRotation(FRotator(90.0, 0.0, 0.0));

		UPrisonBossEffectEventHandler::Trigger_GroundTrailEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringGroundTrail = false;
		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);

		TelegraphDecalComp.DestroyComponent(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 2.5);
		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 2.0);
		Boss.SetActorRotation(Rot);
	}
}