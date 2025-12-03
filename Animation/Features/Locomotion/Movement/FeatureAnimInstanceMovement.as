UCLASS(Abstract)
class UFeatureAnimInstanceMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(BlueprintHidden, NotEditable)
	ULocomotionFeatureMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMovementAnimData AnimData;

	// Add Custom Variables Here
	UPlayerFloorSlowdownComponent SlowDownComponent;
	UPlayerFloorMotionComponent FloorMotionComponent;
	UPlayerMovementComponent MovementComponent;
	UAnimFootTraceComponent FootTraceComp;
	UPlayerSprintComponent SprintComponent;
	UAnimationSettingsComponent AnimSettingsComponent;
	UHazeAnimPlayerBankingComponent BankingComp;
	UPlayerActionModeComponent ActionModeComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeSlopeWarpingData IKData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float SlopeAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableSlopeWarp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float AdditiveBanking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float AdditiveBankAlpha;

	float BankingMultiplier;

	UPROPERTY(BlueprintReadOnly, Category = "Banking")
	UHazeAnimBankingDataAsset BankingAsset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	FRotator InitialRootRotationDelta;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	FRotator CurrentRootRotationDelta;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	bool bInitializeTurn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	bool bTurnLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bStartedToSprint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bPlaySprintStop;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bIsSprinting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bIsSprintToggled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bSkipSprintStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bTriggerSprintActivation;

	// UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	// FPlayerSprintAnimData SprintAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	bool bForceStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsStopping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "TurnAround")
	bool bTurn180;

	bool bTurn180Initialized;
	bool bSprintTurn180Initialized;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "TurnAround")
	bool bSprintTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "TurnAround")
	bool bStartedTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "TurnAround")
	bool bStartedSprintTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightFootFwd;

	// Temp Bool for bypassing sprint enter in forced walk areas.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInForcedWalk;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "MH")
	bool bForceStartInIdleMH;

	bool bCameFromActionMH;

	bool bDecreaseActionMHTimer;

	float ActionTimerThreshold;

	UPROPERTY(Transient, Category = "MH")
	bool bUseActionMH;

	float ActionTimerSpeedMultiplier;

	UPROPERTY(Transient, Category = "MH")
	bool bRelaxIdleBlocked;

	UPROPERTY(Transient, Category = "MH")
	float RelaxTimer;

	float RelaxTriggerTime;

	float AFKIdleTriggerTime;

	UPROPERTY(Transient)
	bool bIsRelaxing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnableRootRotation;

	// TODO: This could be removed by updating the animations to be 'less'. Enabled for now to easily be able to tweak it
	const float MAX_ADDITIVE_BANKING = 0.35;

	// TODO: Currently used for 180 turn experiments
	FRotator CachedActorRotation;
	FRotator CapsuleRotationWhenStartedTurning;

	float IKAlphaInterpSpeed = -1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeIdleAnimationType IdleType;

	float StoppingSprintRatio;

	/**** Counter Balancing on moving objects ****/

	/* These values are currently clamped between -1000 / 1000 and are relative to PlayerForward/Right/Up */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	float BalanceInheritVelocityForward = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	float BalanceInheritVelocityRight = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	float BalanceInheritVelocityUp = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	bool bInheritVelocityForceActionMode = false;

	float InheritVelocityTimer = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	float CounterbalanceAlpha = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Balance")
	float UnstableGroundAlpha = 0;

	float CounterbalanceAlphaMultiplier;

	bool bMovementVerticalSnap;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		FloorMotionComponent = UPlayerFloorMotionComponent::Get(Player);
		SlowDownComponent = UPlayerFloorSlowdownComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		SprintComponent = UPlayerSprintComponent::Get(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
		AnimSettingsComponent = UAnimationSettingsComponent::GetOrCreate(Player);
		BankingComp = UHazeAnimPlayerBankingComponent::GetOrCreate(Player);
		ActionModeComp = UPlayerActionModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		bForceStart = GetAnimBoolParam(n"ForceMovementStart", true, false);

		bSkipStart = (MovementComponent.Velocity.Size() >= 25.0 && bForceStart == false);

		bSkipSprintStart = GetAnimBoolParam(n"SkipSprintStart", true, false);
		bTriggerSprintActivation = (SprintComponent.ShouldOverspeed());

		bUseActionMH = Feature.bUseActionMH;

		bCameFromActionMH = GetAnimBoolParam(n"ExitedToActionMH", true, false);

		// if (SprintComponent.IsSprintToggled())
		// {
		// 	bSkipSprintStart = true;
		// }

		// Temp solution to ensure that regular Idle MH will be taken first if coming from another ABP, until exits can be made custom for ActionMH
		// if (PrevLocomotionAnimationTag != n"Movement" && !bCameFromActionMH)
		// {
		// 	bForceStartInIdleMH = true;
		// }

		// Action MH

		ActionTimerThreshold = Feature.ActionTimerThreshold;

		// Relax MH

		RelaxTimer = 0;

		RelaxTriggerTime = Feature.RelaxTimeRange.Rand();

		AFKIdleTriggerTime = Feature.AFKIdleTimeRange.Rand();

		// Banking
		BankingMultiplier = 0;

		FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);

		IKAlphaInterpSpeed = GetAnimFloatParam(n"BlendIkSpeed", true);
		if (IKAlphaInterpSpeed > SMALL_NUMBER)
		{
			IKAlpha = 0;
		}

		bMovementVerticalSnap = GetAnimTrigger(n"MovementVerticalSnap");
		if (bMovementVerticalSnap)
		{
			IKAlpha = 0;
			IKAlphaInterpSpeed = 0.3;
		}

		IKGoalAlpha = 1;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(n"MovementBlendTime", true, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeWhenResetting() const
	{
		return GetAnimFloatParam(n"MovementResetBlendTime", true, 0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const bool bStartedToMove = CheckValueChangedAndSetBool(bWantsToMove, !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero(), EHazeCheckBooleanChangedDirection::FalseToTrue);
		bStartedToSprint = CheckValueChangedAndSetBool(bIsSprinting, SprintComponent.IsSprinting(), EHazeCheckBooleanChangedDirection::FalseToTrue);

		Velocity = MovementComponent.Velocity;
		Speed = Velocity.Size();

		bIsInForcedWalk = SprintComponent.IsForcedToWalk();

		bIsSprintToggled = SprintComponent.IsSprintToggled();

		if (!SprintComponent.IsSprinting())
		{
			bSkipSprintStart = false;
		}

		bTriggerSprintActivation = (SprintComponent.ShouldOverspeed());


		// ========= Banking =========
		float AdditiveBankingTarget = 0;
		const float BankingTarget = Math::FInterpTo(Banking, BankingComp.GetBankingRatio(DeltaTime, BankingAsset.BankingSettings), DeltaTime, 8);

		if (Math::Abs(Banking) < Math::Abs(BankingTarget))
			AdditiveBankingTarget = (BankingTarget - Banking) * 10;
		AdditiveBanking = Math::FInterpTo(AdditiveBanking, AdditiveBankingTarget, DeltaTime, 7);
		AdditiveBankAlpha = Math::Clamp(Speed / 500 * MAX_ADDITIVE_BANKING, 0.0, MAX_ADDITIVE_BANKING);

		Banking = BankingTarget;

		// If we just blended into this ABP, slowly blend BankingMultiplier back up to 1
		if (!Math::IsNearlyEqual(BankingMultiplier, 1))
		{
			BankingMultiplier = Math::FInterpTo(BankingMultiplier, 1.0, DeltaTime, 2.0);
			AdditiveBankAlpha *= BankingMultiplier;
			Banking *= BankingMultiplier;
		}

		// Check if player is stopping
		if (CheckValueChangedAndSetBool(bIsStopping, bWantsToMove, EHazeCheckBooleanChangedDirection::TrueToFalse))
		{
			StoppingSpeed = Speed;

			// The ammount we're between the Run -> Sprint state, 0 = Run, 1 = Sprint
			StoppingSprintRatio = (StoppingSpeed - FloorMotionComponent.Settings.MaximumSpeed) / (SprintComponent.Settings.MaximumSpeed - FloorMotionComponent.Settings.MaximumSpeed);
			bPlaySprintStop = (StoppingSprintRatio > 0.5) && (PrevLocomotionAnimationTag != n"Landing" && PrevLocomotionAnimationTag != n"Grapple");
		}

		if (bMovementVerticalSnap)
		{
			bEnableIKFeetPlacement = false;
			bEnableSlopeWarp = false;

			if (Speed > 100)
				bMovementVerticalSnap = false;
		}
		else
		{
			// IK Data
			FootTraceComp.UpdateSlopeWarpData(IKData);
			SlopeAngle = MovementComponent.GetSlopeRotationForAnimation().Pitch;
			const bool bForceReTraceAllFeet = CheckValueChangedAndSetBool(bEnableIKFeetPlacement,
																		  FootTraceComp.AreRequirementsMet(),
																		  EHazeCheckBooleanChangedDirection::TrueToFalse);
			if (bEnableIKFeetPlacement)
				FootTraceComp.TraceFeet(IKFeetPlacementData, bForceReTraceAllFeet);
			bEnableSlopeWarp = !bEnableIKFeetPlacement;

			// Blend in the IK rig
			if (IKAlpha < 1)
			{
				IKAlpha = Math::FInterpConstantTo(IKAlpha, 1, DeltaTime, IKAlphaInterpSpeed);
				if (Math::IsNearlyEqual(IKAlpha, 1))
				{
					IKAlpha = 1;
				}
			}
		}

		// 180 starts
		bInitializeTurn = bStartedToMove;
		if (bStartedToMove)
		{
			CapsuleRotationWhenStartedTurning = CachedActorRotation;
			InitialRootRotationDelta = (CachedActorRotation - Player.ActorRotation).Normalized;
			bTurnLeft = InitialRootRotationDelta.Yaw > 0;
		}
		CurrentRootRotationDelta = (CapsuleRotationWhenStartedTurning - Player.ActorRotation).Normalized;
		CachedActorRotation = Player.ActorRotation;

		// bTurn180 = GetAnimTrigger(n"Turn180") || GetAnimTrigger(n"SprintTurn180");
		bTurn180 = FloorMotionComponent.AnimData.bTurnaroundTriggered;
		bSprintTurn180 = FloorMotionComponent.AnimData.bSprintTurnaroundTriggered;
		if (bTurn180 || bSprintTurn180)
		{
			bForceStart = false;
			bSkipStart = true;
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
			SetAnimBoolParam(n"IsInTurnAround", true);
		}
		else
		{
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
			SetAnimBoolParam(n"IsInTurnAround", false);
		}

		bStartedTurn180 = CheckValueChangedAndSetBool(bTurn180Initialized, FloorMotionComponent.AnimData.bTurnaroundTriggered, EHazeCheckBooleanChangedDirection::FalseToTrue);
		bStartedSprintTurn180 = CheckValueChangedAndSetBool(bSprintTurn180Initialized, FloorMotionComponent.AnimData.bSprintTurnaroundTriggered, EHazeCheckBooleanChangedDirection::FalseToTrue);

		bRightFootFwd = Player.IsRightFootForward();

		/*-- Balancing --*/
		FVector InheritMovementVelocity = MovementComponent.GetFollowVelocity();

		BalanceInheritVelocityForward = Math::Clamp(InheritMovementVelocity.DotProduct(Player.ActorForwardVector), -1000, 1000);
		BalanceInheritVelocityRight = Math::Clamp(InheritMovementVelocity.DotProduct(Player.ActorRightVector), -1000, 1000);
		BalanceInheritVelocityUp = Math::Clamp(InheritMovementVelocity.DotProduct(MovementComponent.WorldUp), -1000, 1000);

		if (!FloorMotionComponent.IsMovingBalanceBlocked())
		{
			// Unless ActionMH is blocked, standing on something that has a velocity over a certain threshold will force the players into ActionMH
			if (ActionModeComp.CurrentActionMode != EPlayerActionMode::BlockActionMode &&
				((Math::Abs(BalanceInheritVelocityForward) > 500) || (Math::Abs(BalanceInheritVelocityRight) > 500) || InheritMovementVelocity.ConstrainToPlane(MovementComponent.WorldUp).Size() > 600))
			{
				bInheritVelocityForceActionMode = true;
				InheritVelocityTimer = 0;
			}
			else if (bInheritVelocityForceActionMode)
			{
				InheritVelocityTimer += DeltaTime;
				if (InheritVelocityTimer > 2)
				{
					bInheritVelocityForceActionMode = false;
				}
			}

			// Alpha for counterbalancing
			if (bInheritVelocityForceActionMode)
			{
				CounterbalanceAlpha = Math::FInterpTo(CounterbalanceAlpha, (1 - (CounterbalanceAlphaMultiplier)), DeltaTime, 2);
			}
			else
			{
				CounterbalanceAlpha = Math::FInterpTo(CounterbalanceAlpha, 0, DeltaTime, 2);
			}

			// Lowers the alpha for applying the counterbalancing the more you move
			if (bWantsToMove)
			{
				CounterbalanceAlphaMultiplier = Math::Clamp((Velocity.Size() / 700), Min = 0.65, Max = 0.9);
			}
			else
			{
				CounterbalanceAlphaMultiplier = Velocity.Size() / 700;
			}

			// Alpha for setting how much instability to apply
			if (bInheritVelocityForceActionMode)
			{
				if (bWantsToMove)
				{
					UnstableGroundAlpha = Math::FInterpTo(UnstableGroundAlpha, 0, DeltaTime, 1);
				}
				else
					UnstableGroundAlpha = Math::FInterpTo(UnstableGroundAlpha, 1, DeltaTime, 2);
			}
			else
			{
				UnstableGroundAlpha = Math::FInterpTo(UnstableGroundAlpha, 0, DeltaTime, 2);
			}
		}
		else
		{
			bInheritVelocityForceActionMode = false;
			CounterbalanceAlpha = Math::FInterpTo(CounterbalanceAlpha, 0, DeltaTime, 2);
			CounterbalanceAlphaMultiplier = Velocity.Size() / 700;
			UnstableGroundAlpha = Math::FInterpTo(UnstableGroundAlpha, 0, DeltaTime, 2);
		}

		// Set different IdleAnimationTypes

		// EPlayerActionMode::AllowActionMode - "normal behaviour", Action MH can be taken if action timer is filled up, otherwise regular idle MH
		// EPlayerActionMode::ForceActionMode - "action behaviour", Action MH is forced and regular idle MH, Relaxed MH, and AFKIdle are blocked
		// EPlayerActionMode::BlockActionMode - "relaxed behaviour", Action MH is blocked, and regular idle MH, Relaxed MH, and AFKIdle are allowed

		// If there is an Override Feature running (blade or guns etc) Relax Idles are opt in, otherwise blocked
		bool bHasOverrideFeature = OverrideFeatureTag != n"None";

		bRelaxIdleBlocked = FloorMotionComponent.IsRelaxIdleBlocked();

		if ((ActionModeComp.CurrentActionMode == EPlayerActionMode::ForceActionMode && bUseActionMH) || bInheritVelocityForceActionMode)
		{
			IdleType = EHazeIdleAnimationType::ActionMH;
			RelaxTimer = 0;
		}
		else
		{
			if ((bWantsToMove || ActionModeComp.ActionScore > KINDA_SMALL_NUMBER) || (bHasOverrideFeature && AnimSettingsComponent.GetAllowRelaxAnimDuringOverride() == false) || bRelaxIdleBlocked)
			{
				RelaxTimer = 0;
			}
			else
			{
				RelaxTimer += DeltaTime;
			}

			if (ActionModeComp.GetActionScore() < KINDA_SMALL_NUMBER && !bInheritVelocityForceActionMode)
			{
				IdleType = EHazeIdleAnimationType::MH;
			}

			// Multiplies ActionTimer based on how fast the player is moving. Full run speed = 1
			ActionTimerSpeedMultiplier = Speed / UPlayerFloorMotionSettings::GetSettings(Player).MaximumSpeed;

			if (bWantsToMove && ActionModeComp.CurrentActionMode != EPlayerActionMode::BlockActionMode)
			{
				bDecreaseActionMHTimer = false;
				ActionModeComp.IncreaseActionScore(DeltaTime * ActionTimerSpeedMultiplier);
			}

			if (ActionModeComp.IsCurrentlyInActionMode && ActionModeComp.CurrentActionMode != EPlayerActionMode::BlockActionMode && bUseActionMH)
			{
				IdleType = EHazeIdleAnimationType::ActionMH;
			}
			else
			{
				bDecreaseActionMHTimer = true;
				ActionModeComp.ApplyAllowScoreDecrease(true, this);

				if (ActionModeComp.ActionScore > KINDA_SMALL_NUMBER)
				{
					IdleType = EHazeIdleAnimationType::MH;
				}
				else if (RelaxTimer > AFKIdleTriggerTime && !bInheritVelocityForceActionMode)
				{
					IdleType = EHazeIdleAnimationType::AFKIdle;
				}
				else if (RelaxTimer > RelaxTriggerTime && !bInheritVelocityForceActionMode)
				{
					IdleType = EHazeIdleAnimationType::RelaxedMH;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		ClearAnimBoolParam(n"ForceMovementStart");
		RelaxTimer = 0;
		IdleType = EHazeIdleAnimationType::MH;
		bForceStartInIdleMH = false;
		ClearAnimBoolParam(n"ExitedToActionMH");
	}

	UFUNCTION()
	void AnimNotify_DecelerateToStop()
	{
		bForceStart = false;
		bSkipStart = false;
		bForceStartInIdleMH = false;
	}

	UFUNCTION()
	void AnimNotify_EnteredMh()
	{
		bForceStart = false;
		bSkipStart = false;
	}

	UFUNCTION()
	void AnimNotify_EnteredIdleMH()
	{
		bForceStartInIdleMH = false;
	}

	UFUNCTION()
	void AnimNotify_SprintTurnaroundTriggered()
	{
		bSprintTurn180 = false;
		FloorMotionComponent.AnimData.bSprintTurnaroundTriggered = false;
	}
}
