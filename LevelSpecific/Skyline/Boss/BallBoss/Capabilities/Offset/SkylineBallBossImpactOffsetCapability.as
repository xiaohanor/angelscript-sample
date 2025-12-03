struct FSkylineBallBossImpactOffsetActivationParams
{
	FQuat TargetQuat;
	FVector ImpactVector;
	AActor ThrownActor;
}

class USkylineBallBossImpactOffsetCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);
	default CapabilityTags.Add(SkylineBallBossTags::RotationOffset);
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb; // No crumb! is local, run on both sides, for maximum snappiness

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;
	
	ASkylineBallBoss BallBoss;

	const float MaxLocationOffset = 3500.0;
	const float MaxAngle = 150.0; // Scales to this the more you hit at the side, less in front
	const float StateDuration = 1.0;
	float RotationAccDuration = 0.5;

	FVector StartOffset;
	FQuat StartRot;
	FSkylineBallBossImpactOffsetActivationParams ActivationParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossImpactOffsetActivationParams& Params) const
	{
		if (!BallBoss.ImpactRotation.HitResult.bBlockingHit)
			return false;

		CalculateFromImpact(Params);
		Params.ThrownActor = BallBoss.ImpactRotation.ThrownActor;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.ImpactRotation.ThrownActor != ActivationParams.ThrownActor)
			return true;
		if (ActiveDuration < 0.1)
			return false;
		if (BallBoss.AcceleratedOffsetQuat.VelocityAxisAngle.Size() > KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	void CalculateFromImpact(FSkylineBallBossImpactOffsetActivationParams& OutParams) const
	{
// imagine if Earth is hit by a comet, it would rotate along the impact direction
//           @@@@@     
//    ## @@@@@@@@@@@@@     
//    ##@@@@@@@@@@@@@@@@
//   /@@@@@@@@@@@@@@@@@@@
//  / @@@@@@@@@@@@@@@@@@@
// /   @@@@@@@@@@@@@@@@@
///      @@@@@@@@@@@@@     
//           @@@@@
//
		FVector ImpactDirection = BallBoss.ImpactRotation.ImpactVelocity.GetSafeNormal();
		FVector ImpactUpDirection = (BallBoss.ImpactRotation.HitResult.ImpactPoint - BallBoss.ActorLocation).GetSafeNormal();
		FVector ImpactRotationAxisWorld = ImpactDirection.CrossProduct(ImpactUpDirection).GetSafeNormal();

		float DotProduct = ImpactUpDirection.DotProduct(-ImpactDirection.GetSafeNormal());
		float LessPowerIfWeHitStraightOnAlpha = Math::Clamp(1.0 - Math::Abs(DotProduct), 0.0, 1.0);

		FVector RelativeImpactPoint = (BallBoss.ImpactRotation.HitResult.ImpactPoint - BallBoss.ActorLocation).GetSafeNormal();
		if (ImpactUpDirection.DotProduct(RelativeImpactPoint) > 0.0)
			ImpactRotationAxisWorld *= -1.0;

		if (SkylineBallBossDevToggles::DrawOffset.IsEnabled())
		{
			const float DrawScale = 10000.0;
			Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + ImpactRotationAxisWorld * DrawScale, ColorDebug::Cyan, 20.0, 10.0);
			Debug::DrawDebugLine(BallBoss.ImpactRotation.HitResult.ImpactPoint, BallBoss.ImpactRotation.HitResult.ImpactPoint - ImpactDirection * DrawScale, ColorDebug::Carrot, 20.0, 10.0);
			Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + ImpactUpDirection * DrawScale, ColorDebug::Rose, 20.0, 10.0);
		}

		FVector LocalImpactAxis = BallBoss.ActorQuat.Inverse().RotateVector(ImpactRotationAxisWorld);
		float Alpha = Math::EaseOut(0.3, 1.0, LessPowerIfWeHitStraightOnAlpha, 2.0);
		float NewAngle = MaxAngle * Alpha;
		OutParams.TargetQuat = Math::RotatorFromAxisAndAngle(LocalImpactAxis, NewAngle).Quaternion();
		OutParams.ImpactVector = ImpactDirection * MaxLocationOffset;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossImpactOffsetActivationParams Params)
	{
		BallBoss.ImpactRotation.HitResult = FHitResult();
		ActivationParams = Params;
		BallBoss.BlockCapabilities(SkylineBallBossTags::RotationOffsetIdle, this);
		BallBoss.BlockCapabilities(SkylineBallBossTags::RotationDetonateOffset, this);
		StartOffset = BallBoss.AcceleratedOffsetVector.Value;
		StartRot = BallBoss.AcceleratedOffsetQuat.Value;
		BallBoss.AcceleratedOffsetVector.SnapTo(BallBoss.AcceleratedOffsetVector.Value, ActivationParams.ImpactVector);
		BallBoss.AcceleratedOffsetQuat.SnapTo(BallBoss.AcceleratedOffsetQuat.Value, ActivationParams.TargetQuat.RotationAxis, Math::RadiansToDegrees(ActivationParams.TargetQuat.Angle));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bRecentlyGotDetonated = false;
		BallBoss.ResetTarget();
		BallBoss.UnblockCapabilities(SkylineBallBossTags::RotationOffsetIdle, this);
		BallBoss.UnblockCapabilities(SkylineBallBossTags::RotationDetonateOffset, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Stiffness = 7.5;
		float Dampening = 0.35;
		BallBoss.AcceleratedOffsetVector.SpringTo(StartOffset, Stiffness, Dampening, DeltaTime);
		FVector ImpactInLocalSpace = BallBoss.ActorQuat.UnrotateVector(BallBoss.AcceleratedOffsetVector.Value);
		// Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + ImpactInLocalSpace * 20000.0, ColorDebug::Rose, 20.0, 0.0);
		BallBoss.ImpactLocationOffsetComp.SetRelativeLocation(ImpactInLocalSpace);

		BallBoss.AcceleratedOffsetQuat.SpringTo(StartRot, Stiffness, Dampening, DeltaTime);
		BallBoss.FakeRootComp.SetRelativeRotation(BallBoss.AcceleratedOffsetQuat.Value);
	}
};