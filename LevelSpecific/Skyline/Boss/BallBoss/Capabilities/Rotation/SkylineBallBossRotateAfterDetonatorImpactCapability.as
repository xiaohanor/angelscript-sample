struct FSkylineBallBossRotateAfterDetonatorImpactActivationParams
{
	FQuat TargetQuat;
	float RotationAccDuration;
}

class USkylineBallBossRotateAfterDetonatorImpactCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	FQuat TargetQuat;

	const float MaxAngle = 50.0; // Scales to this the more you hit at the side, less in front
	const float StateDuration = 1.0;
	float RotationAccDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossRotateAfterDetonatorImpactActivationParams& Params) const
	{
		if (!BallBoss.ImpactRotation.HitResult.bBlockingHit)
			return false;

		CalculateFromImpact(Params);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration > StateDuration;
	}

	void CalculateFromImpact(FSkylineBallBossRotateAfterDetonatorImpactActivationParams& OutParams) const
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
		FVector RelativeImpactPoint = (BallBoss.ImpactRotation.HitResult.ImpactPoint - BallBoss.ActorLocation).GetSafeNormal();
		FVector ImpactDirection = BallBoss.ImpactRotation.ImpactVelocity.GetSafeNormal();
		FVector ImpactUpDirection = BallBoss.ImpactRotation.HitResult.ImpactPoint - (BallBoss.ActorLocation - ImpactDirection);
		FVector ImpactRotationAxis = ImpactDirection.CrossProduct(ImpactUpDirection).GetSafeNormal();
		float DotProduct = BallBoss.ImpactRotation.HitResult.ImpactNormal.DotProduct(-ImpactDirection.GetSafeNormal());
		float LessPowerIfWeHitStraightOn = (1.0 - Math::Abs(DotProduct)) * 2.0;
		float NewAngle = MaxAngle * LessPowerIfWeHitStraightOn;
		if (ImpactUpDirection.DotProduct(RelativeImpactPoint) > 0.0)
			NewAngle *= -1.0;
		OutParams.RotationAccDuration = LessPowerIfWeHitStraightOn * StateDuration;
		OutParams.TargetQuat = Math::RotatorFromAxisAndAngle(ImpactRotationAxis, NewAngle).Quaternion() * BallBoss.ActorQuat;
	}

	void CalculateFromCenter()
	{
		FVector RelativeImpact = (BallBoss.ImpactRotation.HitResult.ImpactPoint - BallBoss.ActorLocation).GetSafeNormal();
		FVector ThrowDirection = BallBoss.ImpactRotation.ImpactVelocity.GetSafeNormal();
		FVector NewRelativeForward = (RelativeImpact + ThrowDirection * 0.35).GetSafeNormal();
		TargetQuat = FRotator::MakeFromXZ(NewRelativeForward, BallBoss.ActorUpVector).Quaternion();
		FQuat DiffBetweenTargetAndPart = TargetQuat * BallBoss.ActorQuat.Inverse();
		float DotProduct = BallBoss.ImpactRotation.HitResult.ImpactNormal.DotProduct(-ThrowDirection.GetSafeNormal());
		float LessPowerIfWeHitStraightOn = (1.0 - Math::Abs(DotProduct)) * 2.0;
		float NewAngle = MaxAngle * LessPowerIfWeHitStraightOn;
		RotationAccDuration = LessPowerIfWeHitStraightOn * StateDuration;
		TargetQuat = Math::RotatorFromAxisAndAngle(DiffBetweenTargetAndPart.GetRotationAxis(), NewAngle).Quaternion() * BallBoss.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossRotateAfterDetonatorImpactActivationParams Params)
	{
		RotationAccDuration = Params.RotationAccDuration;
		TargetQuat = Params.TargetQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bRecentlyGotDetonated = false;
		BallBoss.ResetTarget();
		BallBoss.ImpactRotation.HitResult = FHitResult();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
			Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, TargetQuat.Rotator(), 2000.0);
		BallBoss.AcceleratedTargetRotation.AccelerateTo(TargetQuat, RotationAccDuration, DeltaTime);
		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
	}
}