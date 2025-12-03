class USanctuaryBossArenaHydraHeadChasePlayerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	FHazeAcceleratedVector AccTargetPos;
	FHazeAcceleratedQuat AccTargetRot;
	FVector TargetPos;
	FQuat TargetRot;

	USanctuaryCompanionAviationPlayerComponent TargetAviationComp;

	FVector OriginalPosition;
	FQuat OriginalRotation;
	bool bThereAndBackAgain = false;
	bool bHasArrived = false;

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
		if (IsInHandledState(PlayerAviationComp))
			return false;

		return true;
	}

	bool IsInHandledState(USanctuaryCompanionAviationPlayerComponent PlayerAviationComp) const
	{
		if (PlayerAviationComp.AviationState == EAviationState::ToAttack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bThereAndBackAgain)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(HydraHead.TargetPlayer);
		OriginalPosition = HydraHead.HeadPivot.WorldLocation;
		OriginalRotation = HydraHead.HeadPivot.WorldRotation.Quaternion();
		AccTargetPos.SnapTo(OriginalPosition);
		AccTargetRot.SnapTo(OriginalRotation);
		bThereAndBackAgain = false;
		bHasArrived = false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetAviationComp = nullptr;
		HydraHead.OverrideTargetHeadWorldLocation = FVector::ZeroVector;
		HydraHead.LocalHeadState.bToAttackRetract = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TargetAviationComp.AviationState == EAviationState::ToAttack)
		{
			FVector FlatForward = HydraHead.TargetPlayer.ActorForwardVector;
			FlatForward.Z = 0.0;
			TargetPos = HydraHead.TargetPlayer.ActorLocation + FlatForward * HydraHead.Settings.ToAttackHydraInFrontOfPlayerDistance;
			float LeftRightSign = HydraHead.HalfSide == ESanctuaryArenaSideOctant::Left ? 1.0 : -1.0;
			TargetPos += HydraHead.ActorRightVector * LeftRightSign * HydraHead.Settings.ToAttackHydraSidewaysOfPlayerDistance;
			TargetPos.Z += 100.0;
			FVector ToPlayer = HydraHead.TargetPlayer.ActorLocation - HydraHead.HeadPivot.WorldLocation;
			TargetRot = ToPlayer.GetSafeNormal().ToOrientationQuat();
		}
		else
		{
			HydraHead.LocalHeadState.bToAttackRetract = true;
			TargetPos = OriginalPosition;
			TargetRot = OriginalRotation;
			float Distance = (AccTargetPos.Value - TargetPos).Size();
			if (Math::IsNearlyEqual(Distance, 0.0, 1.0))
				bThereAndBackAgain = true;
		}

		UpdateStateBools();

		AccTargetPos.AccelerateTo(TargetPos, 1.0, DeltaTime);
		AccTargetRot.AccelerateTo(TargetRot, 0.5, DeltaTime);
		HydraHead.OverrideTargetHeadWorldLocation = AccTargetPos.Value;
	}

	private void UpdateStateBools()
	{
		HydraHead.LocalHeadState.bToAttackApproach = false;
		HydraHead.LocalHeadState.bToAttackIdle = false;
		if (!HydraHead.GetReadableState().bToAttackRetract)
		{
			float Distance = (AccTargetPos.Value - TargetPos).Size();
			if (Distance > 300.0 && !bHasArrived)
			{
				HydraHead.LocalHeadState.bToAttackApproach = true;
			}
			else
			{
				bHasArrived = true;
				HydraHead.LocalHeadState.bToAttackIdle = true;
			}
		}
	}
};