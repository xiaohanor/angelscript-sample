class USanctuaryBossArenaHydraHeadToAttackProjectileCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	float ProjectileDelay = 0.0;
	float NextProjectileTimestamp = 0.0;

	float LastProjectileTimestamp = 0.0;

	FHazeAcceleratedVector AccTargetPos;
	FHazeAcceleratedQuat AccTargetRot;
	FVector ProjectileDirection;

	int ActiveProjectilingCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HydraHead.TargetPlayer == nullptr)
			return false;

		if (!HydraHead.GetReadableState().bToAttackIdle)
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		if (HydraHead.IsBiting())
			return false;

		if (HydraHead.GetIsIncapacitatedHead())
			return false;

		if (!IsInCorrectAviationState())
			return false;

		return true;
	}

	bool IsInCorrectAviationState() const
	{
		auto AviComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		if (AviComp == nullptr)
			return false;
		if (AviComp.AviationState == EAviationState::ToAttack)
			return true;
		if (AviComp.AviationState == EAviationState::SwoopingBack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HydraHead.GetReadableState().bToAttackIdle)
			return true;

		if (HydraHead.GetIsIncapacitatedHead())
			return true;

		if (!IsInCorrectAviationState())
			return true;

		if (HydraHead.IsBiting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NextProjectileTimestamp = HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left ? HydraHead.Settings.LeftHeadProjectileDelay : HydraHead.Settings.RightHeadProjectileDelay;
		ActiveProjectilingCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.LocalHeadState.bToAttackProjectile = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HydraHead.LocalHeadState.bToAttackProjectile = ActiveProjectilingCount > 0;

		float DistanceToPlayer = (HydraHead.TargetPlayer.ActorLocation - HydraHead.HeadPivot.WorldLocation).Size();
		if (DistanceToPlayer < HydraHead.Settings.ProjectileStopShootNearPlayerDistance)
			return;

		if (NextProjectileTimestamp < ActiveDuration)
		{
			LastProjectileTimestamp = ActiveDuration;
			float ProjectileIntervalMultiplier = 1.0;
			if (HydraHead.LaneBuddy != nullptr && HydraHead.LaneBuddy.GetIsIncapacitatedHead() && HydraHead.Settings.bShootTwiceIfAlone)
				ProjectileIntervalMultiplier = 0.5;
			NextProjectileTimestamp = ActiveDuration + HydraHead.Settings.ProjectileInterval * ProjectileIntervalMultiplier;
			ActiveProjectilingCount += 1;
			
			if (HydraHead.Settings.ProjectileAnimationAnticipationDuration < KINDA_SMALL_NUMBER)
				HydraHead.LaunchToAttackProjectile();
			else
				Timer::SetTimer(this, n"DelayedLaunchAttack", HydraHead.Settings.ProjectileAnimationAnticipationDuration);
		}
	}

	UFUNCTION()
	void DelayedLaunchAttack()
	{
		if (IsActive())
		{
			HydraHead.LaunchToAttackProjectile();
		}
		Timer::SetTimer(this, n"DelayedStopAnimation", HydraHead.Settings.ProjectileAnimationDuration);
	}

	UFUNCTION()
	private void DelayedStopAnimation()
	{
		ActiveProjectilingCount -= 1;
	}
};