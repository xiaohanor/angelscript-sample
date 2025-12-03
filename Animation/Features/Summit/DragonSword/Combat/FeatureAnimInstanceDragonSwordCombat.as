UCLASS(Abstract)
class UFeatureAnimInstanceDragonSwordCombat : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDragonSwordCombat Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDragonSwordCombatAnimData AnimData;

	// Add Custom Variables Here
	UDragonSwordUserComponent BladeComp;
	UDragonSwordCombatUserComponent CombatComp;
	UPlayerMovementComponent MoveComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerTargetablesComponent TargetablesComp;

	/** Attacking */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasAttackStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGroundAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprintAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAirAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRushAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsChargeAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHoldingChargeAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int AttackIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int SequenceIndex;

	/** Rushing */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasRushStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRushing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RushAlpha;

	/** Recoiling */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasRecoilStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RecoilDuration;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RecoilDirection;

	/** Movement */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PrevHorizontalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PrevVerticalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRightFootForward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TargetAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InAirLookAtAlpha = 0;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset FullBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset UpperBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset NullBoneFilter;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDragonSwordCombat NewFeature = GetFeatureAsClass(ULocomotionFeatureDragonSwordCombat);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		BladeComp = UDragonSwordUserComponent::Get(Player);
		CombatComp = UDragonSwordCombatUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);

		PrevVerticalSpeed = Player.ActorRotation.UnrotateVector(MoveComp.PreviousVelocity).Z;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		FDragonSwordCombatAnimData DragonSwordAnimData = CombatComp.AnimData;

		/** Attacking */
		bWasAttackStarted = DragonSwordAnimData.WasAttackStarted();
		bIsGroundAttack = DragonSwordAnimData.IsGroundAttack();
		bIsSprintAttack = DragonSwordAnimData.IsSprintAttack();
		bIsAirAttack = DragonSwordAnimData.IsAirAttack();
		bIsDashAttack = DragonSwordAnimData.IsDashAttack();
		bIsChargeAttack = DragonSwordAnimData.IsChargeAttack();
		bIsHoldingChargeAttack = bIsChargeAttack && CombatComp.bIsHoldingChargeAttack;
		AttackIndex = DragonSwordAnimData.AttackIndex;
		SequenceIndex = DragonSwordAnimData.SequenceIndex;

		/** Movement */
		bIsInAir = MoveComp.IsInAir();
		bHasInput = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bHasVelocity = MoveComp.Velocity.Size() >= SMALL_NUMBER;
		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero() && MoveComp.Velocity.Size() >= SMALL_NUMBER;
		Speed = MoveComp.HorizontalVelocity.Size();
		float TurnRate = StrafeComp.AnimData.StationaryStepTurnAlpha;

		if ((SequenceIndex == 3) || (SequenceIndex == 1))
		{
			bIsRightFootForward = false;
		}
		else
			bIsRightFootForward = true;

		// Push active animations into the user component so we can get the root motion
		BladeComp.ActiveAnimations.Reset();
		GetCurrentlyPlayingAnimations(BladeComp.ActiveAnimations);

		InAirLookAtAlpha = 0;

		if (TargetablesComp != nullptr)
		{
			UTargetableComponent Target = TargetablesComp.GetPrimaryTargetForCategory(DragonSwordCombat::TargetableCategory);
			if (Target != nullptr)
			{
				FVector TargetDirection = (Target.WorldLocation - HazeOwningActor.ActorCenterLocation);
				TargetAngle = Target.Owner.ActorUpVector.DotProduct(TargetDirection);
				TargetAngle = Math::ClampAngle(TargetAngle, -45.0, 45.0);
				/*
				if (HazeOwningActor.ActorUpVector.DotProduct(TargetDirection) > 0)
					TargetAngle *= -1;
				*/
				if (bIsAirAttack && TopLevelGraphRelevantStateName == n"Attacks")
				{
					InAirLookAtAlpha = 1.0;
					InAirLookAtAlpha = Math::EaseInOut(0, 1, InAirLookAtAlpha, 2);
				}
			}
		}

#if EDITOR
		/*
			Print("bWantsToMove: " + bWantsToMove, 0.f);
			Print("AttackIndex: " + AttackIndex, 0.f);
			Print("bIsGroundAttack: " + bIsGroundAttack, 0.f);
		*/

		Print("bIsRightFootForward: " + bIsRightFootForward, 0.f);

		FTemporalLog TemporalLog = TEMPORAL_LOG(CombatComp, "Anim Instance");

		/** Anim Instance */

		// Attacking
		TemporalLog.Value("bWasAttackStarted", bWasAttackStarted);
		TemporalLog.Value("bIsGroundAttack", bIsGroundAttack);
		TemporalLog.Value("bIsSprintAttack", bIsSprintAttack);
		TemporalLog.Value("bIsAirAttack", bIsAirAttack);
		TemporalLog.Value("bIsDashAttack", bIsDashAttack);
		TemporalLog.Value("bIsRushAttack", bIsRushAttack);
		TemporalLog.Value("SequenceIndex", SequenceIndex);
		TemporalLog.Value("AttackIndex", AttackIndex);

		// Rush
		TemporalLog.Value("bWasRushStarted", bWasRushStarted);
		TemporalLog.Value("bIsRushing", bIsRushing);
		TemporalLog.Value("RushAlpha", RushAlpha);

		// Recoiling
		TemporalLog.Value("bWasRecoilStarted", bWasRecoilStarted);
		TemporalLog.Value("bWasRecoilStarted", bWasRecoilStarted);
		TemporalLog.Value("bWasRecoilStarted", bWasRecoilStarted);

		// Movement
		TemporalLog.Value("bIsInAir", bIsInAir);
		TemporalLog.Value("PrevHorizontalSpeed", PrevHorizontalSpeed);
		TemporalLog.Value("PrevVerticalSpeed", PrevVerticalSpeed);
		TemporalLog.Value("bWantsToMove", bWantsToMove);
		TemporalLog.Value("Speed", Speed);
		TemporalLog.Value("RightFootForward", bIsRightFootForward);
		TemporalLog.Value("LookingAtAlpha", InAirLookAtAlpha);
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// if (LocomotionAnimationTag != "Movement")
		// return true;

		// if (CombatComp.bInsideSettleWindow && bWantsToMove)
		// return TopLevelGraphRelevantAnimTime >= 0.15;

		// return TopLevelGraphRelevantAnimTimeRemainingFraction <= SMALL_NUMBER;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		SetAnimFloatParam(n"MovementBlendTime", 0.3);
		StrafeComp.StrafeYawOffset = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeWhenResetting() const
	{
		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeToNullFeature() const
	{
		if (LocomotionAnimationTag == n"Jump" || LocomotionAnimationTag == n"Dash")
			return 0.1;
		return 0.2;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByIndex(EDragonSwordCombatAttackType AttackType, int InSequenceIndex, int Index) const
	{
		const FDragonSwordAttackSequenceData Sequence = Feature.GetSequenceFromAttackType(AttackType, InSequenceIndex);
		return Sequence.GetAnimationFromIndex(Index).Animation;
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		return nullptr;
	}
}