class UPrisonBossMagneticSlamEnterCapability : UPrisonBossChildCapability
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
		if (Boss.CurrentAttackType != EPrisonBossAttackType::MagneticSlam)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::MagneticSlamEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsExitingMagneticSlamNoBlast = false;
		Boss.AnimationData.bIsExitingMagneticSlam = false;
		Boss.AnimationData.bMagneticSlamHitReaction = false;

		StartLocation = Boss.ActorLocation;
		TargetLocation = Boss.TargetDangerZone.ActorLocation;
		TargetRotation = Boss.TargetDangerZone.ActorRotation;

		Boss.AnimationData.bIsEnteringMagneticSlam = true;

		Boss.TriggerInactiveDangerZones();

		TelegraphDecalComp = Decal::SpawnDecalAtLocation(AttackDataComp.MagneticSlamDecalMaterial, FVector(100.0, 400.0, 400.0), TargetLocation);
		TelegraphDecalComp.SetWorldRotation(FRotator(90.0, 0.0, 0.0));

		/*FPrisonBossVolleyData VolleyData;
		VolleyData.ProjectilesPerVolley = 4;
		Boss.UpdateVolleyData(VolleyData);*/

		Boss.DeactivateVolley();

		UPrisonBossEffectEventHandler::Trigger_MagneticSlamEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringMagneticSlam = false;
		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);

		TelegraphDecalComp.DestroyComponent(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Boss.AttackDataComp.EaseInOutCurve.GetFloatValue(Math::Saturate(ActiveDuration/PrisonBoss::MagneticSlamEnterDuration));
		FVector Loc = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 2.0);
		Boss.SetActorRotation(Rot);
	}
}