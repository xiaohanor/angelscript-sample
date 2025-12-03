class USanctuaryBossArenaHydraHeadToAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;
	USanctuaryCompanionAviationPlayerComponent TargetAviationComp;

	bool bExiting = false;
	float RetractingTimestamp = 0.0;
	bool bDone = false;

	FHazeAcceleratedVector AccTargetPos;

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

		auto PlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		if (PlayerAviationComp == nullptr)
			return false;

		if (!PlayerAviationComp.GetIsAviationActive())
			return false;

		// if (!ShouldHydraHeadLockOn(PlayerAviationComp))
		// 	return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.TargetPlayer == nullptr)
			return true;

		auto PlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		if (PlayerAviationComp == nullptr)
			return true;

		if (!PlayerAviationComp.GetIsAviationActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		HydraHead.LocalHeadState.bToAttackIdle = true;
		HydraHead.LocalHeadState.bToAttackApproach = true;
		bExiting = false;
		bDone = false;
		FVector OriginalHeadPos = HydraHead.HeadPivot.WorldLocation;
		AccTargetPos.SnapTo(OriginalHeadPos);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetAviationComp = nullptr;
		HydraHead.LocalHeadState.bToAttackApproach = false;
		HydraHead.LocalHeadState.bToAttackIdle = false;
		HydraHead.LocalHeadState.bToAttackRetract = false;
		HydraHead.OverrideTargetHeadWorldLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector BackwardsLocation = HydraHead.BasePivot.WorldLocation + HydraHead.BasePivot.WorldRotation.RotateVector(HydraHead.OriginalHeadRelativeLocation);
		BackwardsLocation.Z = HydraHead.TargetPlayer.ActorLocation.Z + 1000.0;
		FVector BackwardsOffset = FVector();
		if (TargetAviationComp.AviationState == EAviationState::ToAttack)
			BackwardsOffset = -HydraHead.ActorForwardVector * 4000.0;
		BackwardsLocation += BackwardsOffset;
		FVector ToPlayerDistance = HydraHead.TargetPlayer.ActorLocation - BackwardsLocation;
		
		// Debug::DrawDebugString(HydraHead.TargetPlayer.ActorLocation, "To Player: " + ToPlayerDistance.Size());

		if (ToPlayerDistance.Size() < HydraHead.Settings.ToAttackAvoidPlayerDistance && !SanctuaryHydraDevToggles::DisableAvoidPlayer.IsEnabled())
		{
			float RequiredDistance = HydraHead.Settings.ToAttackAvoidPlayerDistance - ToPlayerDistance.Size();
			FVector AwayFromPlayerOffset = ToPlayerDistance.GetSafeNormal() * -1.0 * RequiredDistance;
			AwayFromPlayerOffset.Z *= -1.0;
			BackwardsLocation += AwayFromPlayerOffset;
		}

		// AccTargetPos.AccelerateTo(BackwardsLocation, 2.0, DeltaTime);
		HydraHead.OverrideTargetHeadWorldLocation = BackwardsLocation;
	}

	// void OldTick(float DeltaTime)
	// {
	// 	if (!HydraHead.IsBiting())
	// 	{
	// 		if (HydraHead.GetReadableState().bToAttackApproach || HydraHead.GetReadableState().bToAttackIdle)
	// 		{
	// 			FVector TargetWorldLocation = HydraHead.BasePivot.WorldLocation + HydraHead.BasePivot.WorldRotation.RotateVector(HydraHead.OriginalHeadRelativeLocation);
	// 			TargetWorldLocation.Z = HydraHead.TargetPlayer.ActorLocation.Z + 1000.0;
	// 			AccTargetPos.AccelerateTo(TargetWorldLocation, HydraHead.Settings.ApproachDuration, DeltaTime);
	// 			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
	// 		}
	// 		if (HydraHead.GetReadableState().bToAttackRetract)
	// 		{
	// 			FVector TargetWorldLocation = HydraHead.BasePivot.WorldLocation + HydraHead.BasePivot.WorldRotation.RotateVector(HydraHead.OriginalHeadRelativeLocation);
	// 			AccTargetPos.AccelerateTo(TargetWorldLocation, HydraHead.Settings.RetractDuration, DeltaTime);
	// 			HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
	// 		}
	// 	}

	// 	if (ActiveDuration > HydraHead.Settings.ApproachDuration)
	// 		HydraHead.LocalHeadState.bToAttackApproach = false;

	// 	bool bTryExit = bExiting || !ShouldHydraHeadLockOn(TargetAviationComp);
	// 	if (bTryExit && !HydraHead.IsAttacking())
	// 	{
	// 		if (!bExiting)
	// 			RetractingTimestamp = ActiveDuration;
	// 		bExiting = true;
	// 		HydraHead.LocalHeadState.bToAttackRetract = true;
	// 		if (RetractingTimestamp + HydraHead.Settings.RetractDuration > ActiveDuration)
	// 			bDone = true;
	// 	}
	// }

	bool ShouldHydraHeadLockOn(USanctuaryCompanionAviationPlayerComponent AviationComp) const
	{
		if (AviationComp.GetAviationState() == EAviationState::SwoopingBack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::Entry)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::ToAttack)
			return true;
		if (AviationComp.GetAviationState() == EAviationState::TryExitAttack)
			return true;
		// if (TargetPlayerAviationComp.AviationState == EAviationState::InitAttack)
		// 	return true;
		// if (TargetPlayerAviationComp.AviationState == EAviationState::SwoopInAttack)
		// 	return true;
		return false;
	}
};