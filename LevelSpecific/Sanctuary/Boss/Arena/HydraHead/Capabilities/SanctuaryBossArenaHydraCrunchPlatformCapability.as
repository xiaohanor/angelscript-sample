class USanctuaryBossArenaHydraCrunchPlatformCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	bool bBiteDone = false;
	FHazeAcceleratedVector AccTargetPos;
	FVector OriginalHeadPos;
	bool bBitPlatform = false;

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

		if (!HydraHead.GetReadableState().IsIdling())
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		if (HydraHead.PlatformsToCrunchQueue.Num() == 0)
			return false;

		return true;
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
		OriginalHeadPos = HydraHead.HeadPivot.WorldLocation;
		AccTargetPos.SnapTo(OriginalHeadPos);
		HydraHead.PlatformsToCrunchQueue[0].Targeted();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.OverrideTargetHeadWorldLocation = FVector::ZeroVector;
		bBiteDone = false;
		bBitPlatform = false;
		HydraHead.LocalHeadState.bToAttackBiteLunge = false;
		HydraHead.LocalHeadState.bToAttackBiteDown = false;
		HydraHead.LocalHeadState.bToAttackBiteRetract = false;
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
		HydraHead.LocalHeadState.bToAttackBiteRetract = !HydraHead.GetReadableState().bToAttackBiteLunge && !HydraHead.GetReadableState().bToAttackBiteDown && DelayedActiveDuration < AccumulatedDuration;
		bBiteDone = DelayedActiveDuration >= AccumulatedDuration;

		if (HydraHead.GetReadableState().bToAttackBiteLunge)
		{
			float AlphaProgressArc = Math::Clamp(DelayedActiveDuration / HydraHead.Settings.BiteLungeDuration, 0.0, 1.0) * 2.0;
			if (AlphaProgressArc > 1.0)
				AlphaProgressArc = 1.0 - AlphaProgressArc;
			
			FVector TargetLocation = GetTargetLocation();
			TargetLocation.Z += Math::EaseOut(0.0, HydraHead.Settings.BiteArcHeight, AlphaProgressArc,2.0);
			AccTargetPos.AccelerateTo(TargetLocation, HydraHead.Settings.BiteLungeDuration, DeltaTime);
			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE LUNGE", ColorDebug::Marigold, 0.0);
		}
		else if (HydraHead.GetReadableState().bToAttackBiteDown)
		{
			AccTargetPos.AccelerateTo(GetTargetLocation(), HydraHead.Settings.BiteLungeDuration, DeltaTime);
			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;

			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE DOWN", ColorDebug::Leaf, 0.0);
		}
		else if (HydraHead.GetReadableState().bToAttackBiteRetract)
		{
			if (!bBitPlatform)
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_CrunchPlatform(HydraHead);
				bBitPlatform = true;
				HydraHead.PlatformsToCrunchQueue[0].Crunched();
				HydraHead.PlatformsToCrunchQueue.RemoveAt(0);
			}
			AccTargetPos.AccelerateTo(GetTargetLocation(), HydraHead.Settings.BiteRetractDuration, DeltaTime);
			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
			if (bDebug)
				Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\n\n\n BITE RETRACT", ColorDebug::Cerulean, 0.0);
		}
	}

	FVector GetTargetLocation()
	{
		FVector TargetLocation = OriginalHeadPos;
		if (!bBitPlatform && HydraHead.PlatformsToCrunchQueue.Num() > 0)
		{
			TargetLocation = HydraHead.PlatformsToCrunchQueue[0].ActorLocation;
			float LeftRightSign = HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left ? 1.0 : -1.0 ;
			FVector RightOffset = HydraHead.ActorRightVector * HydraHead.Settings.BiteHorizontalOffset * LeftRightSign;
			FVector VerticalOffset = HydraHead.ActorUpVector * HydraHead.Settings.BiteVerticalOffset * LeftRightSign;
			FVector BackwardsOffset = HydraHead.ActorForwardVector * -1.0 * 2000.0;
			TargetLocation += RightOffset + VerticalOffset + BackwardsOffset;
		}
		return TargetLocation;
	}
};