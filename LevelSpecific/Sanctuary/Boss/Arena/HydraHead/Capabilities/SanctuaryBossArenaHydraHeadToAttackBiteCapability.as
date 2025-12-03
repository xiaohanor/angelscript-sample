class USanctuaryBossArenaHydraHeadToAttackBiteCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;
	USanctuaryCompanionAviationPlayerComponent TargetAviationComp;

	bool bBiteDone = false;
	FHazeAcceleratedVector AccTargetPos;
	FVector OriginalHeadPos;
	bool bBitPlayer = false;

	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < HydraHead.Settings.BiteCooldown)
			return false;

		if (HydraHead.TargetPlayer == nullptr)
			return false;

		if (!HydraHead.GetReadableState().bToAttackIdle)
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		float DistanceToPlayer = (HydraHead.TargetPlayer.ActorLocation - HydraHead.HeadPivot.WorldLocation).Size();
		if (DistanceToPlayer > HydraHead.Settings.BiteTriggerDistanceToPlayer)
			return false;

		if (TargetAviationComp != nullptr && TargetAviationComp.AviationState != EAviationState::ToAttack)
			return false;

		return false;  // disabled. Doing it in a sequence now ~
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bBiteDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDebug = SanctuaryHydraDevToggles::Drawing::PrintHydraState.IsEnabled();
		if (TargetAviationComp == nullptr)
			TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		OriginalHeadPos = HydraHead.HeadPivot.WorldLocation;
		AccTargetPos.SnapTo(OriginalHeadPos);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.OverrideTargetHeadWorldLocation = FVector::ZeroVector;
		bBiteDone = false;
		bBitPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Delay = HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left ? HydraHead.Settings.BiteDelayLeftHead : HydraHead.Settings.BiteDelayRightHead;
		if (ActiveDuration < Delay)
			return;

		float DelayedActiveDuration = ActiveDuration - Delay;

		if (bDebug)
			Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n BITE", ColorDebug::Vermillion, 0.0);

		float AccumulatedDuration = HydraHead.Settings.BiteLungeDuration;
		HydraHead.LocalHeadState.bToAttackBiteLunge = DelayedActiveDuration < AccumulatedDuration;
		AccumulatedDuration += HydraHead.Settings.BiteDownDuration;
		HydraHead.LocalHeadState.bToAttackBiteDown = !HydraHead.GetReadableState().bToAttackBiteLunge && DelayedActiveDuration < AccumulatedDuration;
		AccumulatedDuration += HydraHead.Settings.BiteRetractDuration;
		HydraHead.LocalHeadState.bToAttackBiteRetract = !HydraHead.GetReadableState().bToAttackBiteDown && DelayedActiveDuration < AccumulatedDuration;
		bBiteDone = DelayedActiveDuration >= AccumulatedDuration;

		if (HydraHead.GetReadableState().bToAttackBiteLunge)
		{
			float AlphaProgressArc = Math::Clamp(DelayedActiveDuration / HydraHead.Settings.BiteLungeDuration, 0.0, 1.0) * 2.0;
			if (AlphaProgressArc > 1.0)
				AlphaProgressArc = 1.0 - AlphaProgressArc;
			FVector TargetLocation = HydraHead.TargetPlayer.ActorLocation + HydraHead.TargetPlayer.ActorForwardVector * HydraHead.Settings.BiteInFrontOfPlayerDistance;
			float LeftRightSign = HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left ? 1.0 : -1.0 ;
			FVector RightOffset = HydraHead.ActorRightVector * HydraHead.Settings.BiteHorizontalOffset * LeftRightSign;
			FVector VerticalOffset = HydraHead.ActorUpVector * HydraHead.Settings.BiteVerticalOffset * LeftRightSign;
			TargetLocation += RightOffset + VerticalOffset;
			TargetLocation.Z += Math::EaseOut(0.0, HydraHead.Settings.BiteArcHeight, AlphaProgressArc,2.0);
			AccTargetPos.AccelerateTo(TargetLocation, HydraHead.Settings.BiteLungeDuration, DeltaTime);
			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE LUNGE", ColorDebug::Marigold, 0.0);
		}
		else if (HydraHead.GetReadableState().bToAttackBiteDown)
		{
			if (!bBitPlayer)
			{
				FTransform ToungeTransform = HydraHead.SkeletalMesh.GetSocketTransform(HydraHead.SpitProjectileName);
				float DistanceToPlayer = (HydraHead.TargetPlayer.ActorLocation - ToungeTransform.Location).Size();
				if (bDebug)
					Debug::DrawDebugSphere(ToungeTransform.Location, HydraHead.Settings.BiteHurtDistanceToPlayer, 12, ColorDebug::Red, 5.0, 0.0, true);
				if (DistanceToPlayer < HydraHead.Settings.BiteHurtDistanceToPlayer)
				{
					UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(HydraHead.TargetPlayer);
					HealthComp.DamagePlayer(0.33, nullptr, nullptr);
					HydraHead.TargetPlayer.PlayForceFeedback(HydraHead.BiteForceFeedbackEffect, false, false, this, 1.0);
					bBitPlayer = true;
				}
			}
			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE DOWN", ColorDebug::Leaf, 0.0);
		}
		else if (HydraHead.GetReadableState().bToAttackBiteRetract)
		{
			AccTargetPos.AccelerateTo(OriginalHeadPos, HydraHead.Settings.BiteRetractDuration, DeltaTime);
			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE RETRACT", ColorDebug::Cerulean, 0.0);
		}
	}
};