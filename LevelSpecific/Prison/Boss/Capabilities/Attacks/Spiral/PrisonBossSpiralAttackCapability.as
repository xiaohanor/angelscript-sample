class UPrisonBossSpiralAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector GroundLocation;
	bool bReachedEndOfSpline = false;

	float EndDelay = 0.0;

	APrisonBossGroundTrailAttack GroundTrailAttack;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bReachedEndOfSpline && EndDelay >= PrisonBoss::SpiralExplodeDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EndDelay = 0.0;
		bReachedEndOfSpline = false;

		Boss.AnimationData.bIsSpiralling = true;

		GroundTrailAttack = SpawnActor(AttackDataComp.GroundTrailClass);
		GroundTrailAttack.ActivateTrailAttached(Boss.RootComponent, Boss.SpiralSpline.Spline);

		UPrisonBossEffectEventHandler::Trigger_SpiralStartTrail(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FVector SplineLoc = Boss.SpiralSpline.Spline.GetWorldLocationAtSplineFraction(1.0);
		FRotator SplineRot = Boss.SpiralSpline.Spline.GetWorldRotationAtSplineFraction(1.0).Rotator();
		SplineRot.Yaw += 180.0;

		Boss.SetActorLocationAndRotation(SplineLoc, SplineRot);

		Boss.AnimationData.bIsSpiralling = false;

		GroundTrailAttack.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GroundTrailAttack.Explode(true);

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Medium);

		UPrisonBossEffectEventHandler::Trigger_SpiralExplode(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float DurationAlpha = ActiveDuration/PrisonBoss::SpiralAttackDuration;
		float Alpha = Boss.SpiralCurve.GetFloatValue(DurationAlpha);

		float SplineAlpha = Math::Lerp(1.0, 0.0, Alpha);
		FVector SplineLoc = Boss.SpiralSpline.Spline.GetWorldLocationAtSplineFraction(SplineAlpha);
		FRotator SplineRot = Boss.SpiralSpline.Spline.GetWorldRotationAtSplineFraction(SplineAlpha).Rotator();
		SplineRot.Yaw += 180.0;

		Boss.SetActorLocation(SplineLoc);
		Boss.SetActorRotation(SplineRot);

		if (Alpha >= 1.0)
		{
			EndDelay += DeltaTime;
			bReachedEndOfSpline = true;
		}
	}
}