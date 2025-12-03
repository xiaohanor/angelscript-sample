class UPrisonBossHackableMagneticProjectileHitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	bool bProjectileLaunched = false;
	bool bProjectileHacked = false;

	UHazeSplineComponent SplineComp;
	float SplineFraction = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if (Boss.CurrentAttackType != EPrisonBossAttackType::HackableMagneticProjectile)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::HackableMagneticProjectileHitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineComp = Boss.CircleSplineAirOuterUpper.Spline;

		Boss.AnimationData.bHackableMagneticProjectileHitReaction = true;

		UPrisonBossEffectEventHandler::Trigger_HackableMagneticProjectileHitBoss(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.SetTargetIdleTime(1.0);

		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.AnimationData.bHackableMagneticProjectileHitReaction = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}