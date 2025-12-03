struct FSkylineBossFocusBeamSweepAttackActivateParams
{
	AHazeActor Target;
	FVector TargetLocation;

	FVector StartLocation;
	FVector EndLocation;
};

class USkylineBossFocusBeamSweepAttackCapability : USkylineBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFocusBeamAttack);

	USkylineBossFocusBeamComponent FocusBeamComp;

	AHazeActor Target;
	FVector TargetLocation;
	FVector StartLocation;
	FVector EndLocation;

	const float SweepLength = 3500.0;
	const float SweepDuration = 0.5;
	const float FireDelay = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FocusBeamComp = USkylineBossFocusBeamComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossFocusBeamSweepAttackActivateParams& Params) const
	{
		if(Boss.GetStateActiveDuration() < 4)
			return false;

		if (DeactiveDuration < 1.0) // 1.5
			return false;

		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
			return false;

		Params.Target = Boss.LookAtTarget.Get();
		Params.TargetLocation = Params.Target.ActorLocation + Params.Target.ActorForwardVector * -1.0;

		const float RandomDirection = (Math::RandBool() ? 1.0 : -1.0);

		auto GravityBike = Cast<AGravityBikeFree>(Target);
		if (GravityBike != nullptr)
		{
			const FVector PredictedAttackLocation = GravityBike.ActorLocation + GravityBike.ActorVelocity * 2.0;

			FVector AttackDirection = GravityBike.ActorVelocity.CrossProduct(FVector::UpVector).SafeNormal;
			AttackDirection = AttackDirection.RotateAngleAxis(Math::RandRange(-45.0, 45.0), FVector::UpVector);

			Params.StartLocation = PredictedAttackLocation - AttackDirection * SweepLength * RandomDirection;
			Params.EndLocation = PredictedAttackLocation + AttackDirection * SweepLength * RandomDirection;
		}
		else
		{
			const FVector ToTarget = Params.TargetLocation - FocusBeamComp.WorldLocation;
			FVector AttackDirection = FVector::UpVector.CrossProduct(ToTarget).GetSafeNormal();
			AttackDirection = AttackDirection.RotateAngleAxis(Math::RandRange(-45.0, 45.0), FVector::UpVector);

			Params.StartLocation = Params.TargetLocation - AttackDirection * SweepLength * RandomDirection;
			Params.EndLocation = Params.TargetLocation + AttackDirection * SweepLength * RandomDirection;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > FireDelay + SweepDuration)
			return true;

//		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossFocusBeamSweepAttackActivateParams Params)
	{
		Target = Params.Target;
		TargetLocation = Params.TargetLocation;
		StartLocation = Params.StartLocation;
		EndLocation = Params.EndLocation;

		Boss.AnimData.bFiringLaser = true;
		USkylineBossEventHandler::Trigger_BeamStart(Boss);

		//Audio
		auto BeamManager = SkylineBossFocusBeam::GetManager();
		BeamManager.StartNewImpactPool();
		USkylineBossEventHandler::Trigger_ImpactPoolStart(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimData.bFiringLaser = false;
		USkylineBossEventHandler::Trigger_BeamStop(Boss);

		if(FocusBeamComp.IsBeamActive())
			FocusBeamComp.DeactivateBeams();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!FocusBeamComp.IsBeamActive() && ActiveDuration > FireDelay)
		{
			ActivateLaserBeam();
		}

		if (!FocusBeamComp.IsBeamActive())
			return;

		float Alpha = (ActiveDuration - FireDelay) / SweepDuration;

		TargetLocation = Math::Lerp(StartLocation, EndLocation, Alpha);

		bool bWasFirstImpact = false;
		FHitResult Hit = FocusBeamComp.TraceAttack(TargetLocation, bWasFirstImpact);

		FocusBeamComp.UpdateBeams(Hit);
		FocusBeamComp.UpdateBeamHit(Hit, bWasFirstImpact);
	
		Boss.AnimData.bFiringLaser = true;
		Boss.AnimData.LaserLocation = Hit.IsValidBlockingHit() ? Hit.ImpactPoint : Hit.TraceEnd;
	}

	void ActivateLaserBeam()
	{
		FocusBeamComp.ActivateBeams(Target);
	}
}