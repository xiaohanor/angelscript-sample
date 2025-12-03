UCLASS(Abstract)
class UFeatureAnimInstanceGravityBladeCombat : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBladeCombat Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBladeCombatAnimData AnimData;
	
	// Add Custom Variables Here
	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	UPlayerMovementComponent MoveComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerTargetablesComponent TargetablesComp;
	

	/** Attacking */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasAttackStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAttacking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EGravityBladeAttackAnimationType CurrentAttackType;

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

	/** Speed up */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentSpeedUpPlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentSpeedUpStartTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentSpeedUpRushSpeedMultiplier;

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

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AngleLeftToRotate;


	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset FullBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset UpperBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset NullBoneFilter;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityBladeCombat NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBladeCombat);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		BladeComp = UGravityBladeUserComponent::Get(Player);	
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);	
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

		FGravityBladeCombatAnimData GravityBladeAnimData = CombatComp.AnimData;

		/** Attacking */
		bWasAttackStarted = GravityBladeAnimData.WasAttackStarted();
		bIsAttacking = GravityBladeAnimData.IsAttacking();
		CurrentAttackType = GravityBladeAnimData.AnimationType;

		bIsGroundAttack = GravityBladeAnimData.IsGroundAttack();
		bIsSprintAttack = GravityBladeAnimData.AnimationType == EGravityBladeAttackAnimationType::SprintAttack;
		bIsAirAttack =  GravityBladeAnimData.IsAirAttack();
		bIsDashAttack = GravityBladeAnimData.AnimationType == EGravityBladeAttackAnimationType::DashAttack;
		bIsRushAttack = GravityBladeAnimData.IsRushAttack();
		AttackIndex = GravityBladeAnimData.AttackIndex;
		SequenceIndex = GravityBladeAnimData.SequenceIndex;

		/** Rushing */
		bWasRushStarted = GravityBladeAnimData.WasRushStarted();
		bIsRushing = GravityBladeAnimData.bIsRushing;
		RushAlpha = GravityBladeAnimData.RushAlpha;

		/** Recoiling */
		bWasRecoilStarted = GravityBladeAnimData.RecoiledThisFrame();
		RecoilDuration = GravityBladeAnimData.RecoilDuration;
		RecoilDirection = GravityBladeAnimData.RecoilDirection;

		/** Speed up */
		CurrentSpeedUpPlayRate = GravityBladeAnimData.CurrentSpeedUpPlayRate;
		CurrentSpeedUpStartTime = GravityBladeAnimData.CurrentSpeedUpStartTime;
		CurrentSpeedUpRushSpeedMultiplier = GravityBladeAnimData.CurrentSpeedUpRushSpeedMultiplier;

		/** Movement */
		bIsInAir = MoveComp.IsInAir();
		bHasInput = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bHasVelocity = MoveComp.Velocity.Size() >= SMALL_NUMBER;
		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero() && MoveComp.Velocity.Size() >= SMALL_NUMBER;
		Speed = MoveComp.HorizontalVelocity.Size();	
		float TurnRate = StrafeComp.AnimData.StationaryStepTurnAlpha;	

		bIsRightFootForward = GravityBladeAnimData.bFirstFrameHasRightFootForward;
		AngleLeftToRotate = GravityBladeAnimData.AngleLeftToRotate;
		
		// Push active animations into the user component so we can get the root motion
		BladeComp.ActiveAnimations.Reset();
		GetCurrentlyPlayingAnimations(BladeComp.ActiveAnimations);

		InAirLookAtAlpha = 0;

		if (TargetablesComp != nullptr)
		{	
			UTargetableComponent Target = TargetablesComp.GetPrimaryTargetForCategory(GravityBladeCombat::TargetableCategory);
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
					InAirLookAtAlpha = 0.5;
					InAirLookAtAlpha = Math::EaseInOut(0, 1, InAirLookAtAlpha, 2);
				}
			}
		}

		#if EDITOR	
		/*
			Print("bWantsToMove: " + bWantsToMove, 0.f);
			Print("AttackIndex: " + AttackIndex, 0.f);
			Print("bIsGroundAttack: " + bIsGroundAttack, 0.f);
			Print("bIsRightFootForward: " + bIsRightFootForward, 0.f);
		*/
			

			FTemporalLog TemporalLog = TEMPORAL_LOG(CombatComp, "Anim Instance");

			/** Anim Instance */

			// Attacking
			TemporalLog.Value("bWasAttackStarted", bWasAttackStarted);
			TemporalLog.Value("bIsGroundAttack", bIsGroundAttack);
			TemporalLog.Value("bIsSprintAttack", bIsSprintAttack);
			TemporalLog.Value("bIsAirAttack", bIsAirAttack);
			TemporalLog.Value("bIsDashAttack", bIsDashAttack);
			TemporalLog.Value("bIsRushAttack", bIsRushAttack);
			TemporalLog.Value("AttackIndex", AttackIndex);
			TemporalLog.Value("SequenceIndex", SequenceIndex);
			TemporalLog.Value("bIsAttacking", bIsAttacking);

			// Rush
			TemporalLog.Value("bWasRushStarted", bWasRushStarted);
			TemporalLog.Value("bIsRushing", bIsRushing);
			TemporalLog.Value("RushAlpha", RushAlpha);

			// Recoiling
			TemporalLog.Value("bWasRecoilStarted", bWasRecoilStarted);
			TemporalLog.Value("RecoilDuration", RecoilDuration);
			TemporalLog.Value("RecoilDirection", RecoilDirection);

			// Speed up
			TemporalLog.Value("CurrentSpeedUpPlayRate", CurrentSpeedUpPlayRate);
			TemporalLog.Value("CurrentSpeedUpStartTime", CurrentSpeedUpStartTime);
			TemporalLog.Value("CurrentSpeedUpRushSpeedMultiplier", CurrentSpeedUpRushSpeedMultiplier);

			// Movement
			TemporalLog.Value("bIsInAir", bIsInAir);
			TemporalLog.Value("PrevHorizontalSpeed", PrevHorizontalSpeed);
			TemporalLog.Value("PrevVerticalSpeed", PrevVerticalSpeed);
			TemporalLog.Value("bWantsToMove", bWantsToMove);
			TemporalLog.Value("Speed", Speed);
			TemporalLog.Value("RightFootForward", bIsRightFootForward);
			TemporalLog.Value("LookingAtAlpha", InAirLookAtAlpha);
			TemporalLog.Value("AngleLeftToRotate", AngleLeftToRotate);
		#endif

	}

	
	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != "Movement")
			return true; 

		if (CombatComp.bInsideSettleWindow && bWantsToMove)
			return TopLevelGraphRelevantAnimTime >= 0.15;
		
		return TopLevelGraphRelevantAnimTimeRemainingFraction <= SMALL_NUMBER;
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

	// Will return either the interaction attack (if current attack is an interaction attack) or just a normal attack based on anim data.
	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetCurrentAttackAnimation() const
	{
		return GetAnimationByIndex(CurrentAttackType, SequenceIndex, AttackIndex);
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByName(EGravityBladeAttackAnimationType AttackType, int InSequenceIndex, FName AnimationName) const
	{
		const FGravityBladeAttackSequenceData Sequence = Feature.GetSequenceFromAttackType(AttackType, InSequenceIndex);
		return Sequence.GetAnimationFromName(AnimationName).Animation;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByIndex(EGravityBladeAttackAnimationType AttackType, int InSequenceIndex, int Index) const
	{
		const FGravityBladeAttackSequenceData Sequence = Feature.GetSequenceFromAttackType(AttackType, InSequenceIndex);
		return Sequence.GetAnimationFromIndex(Index).Animation;
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		return nullptr;
	}
}