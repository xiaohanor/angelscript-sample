

class UIslandNunchuckDefaultComboMoveAsset : UIslandNunchuckMoveAssetBase
{	
	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidatePlayerGroundedType = false;

	// Respond to the players grounded status
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidatePlayerGroundedType"))
	EIslandNunchuckGroundedSettingsType PlayerGroundedType = EIslandNunchuckGroundedSettingsType::Grounded;
	
	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidateTargetableGroundedType = false;

	// Respond to the targetable components 'GroundedType' setting
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidateTargetableGroundedType"))
	EIslandNunchuckGroundedSettingsType TargetableGroundedType = EIslandNunchuckGroundedSettingsType::Grounded; 

	// Do we need a distance to the target to trigger
	UPROPERTY(Category = "Settings")
	FHazeRange RequiredDistanceToTarget = FHazeRange(-1, -1);

	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidateRequiresTraversalToBe = false;

	// Respond to the TargetableComponent's 'bCanTraversToTarget'
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidateRequiresTraversalToBe"))
	EIslandNunchuckTriggerSettingsType RequiresTraversalToBe = EIslandNunchuckTriggerSettingsType::True;

	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidateRequiresStationaryTargetToBe = false;

	// Respond to the TargetableComponent's 'bTargetIsStationary'
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidateRequiresStationaryTargetToBe"))
	EIslandNunchuckTriggerSettingsType RequiresStationaryTargetToBe = EIslandNunchuckTriggerSettingsType::True;

	UPROPERTY(Category = "Animation|Settings", meta = (EditCondition = "!bIsPartOfComboChain || ComboChainIndex==1"))
	float BlendTime = 0;

	UPROPERTY(Category = "Animation")
	FIslandNunchuckAnimationWithSettleData Animation;

	float GetBlendInTime() const
	{
		if(bIsPartOfComboChain && ComboChainIndex != 1)
			return 0;

		return Math::Max(BlendTime, 0);
	}
}

struct FIslandNunchuckDefaultComboMoveActivation
{
	UIslandNunchuckTargetableComponent Target;
	UIslandNunchuckDefaultComboMoveAsset Move;
}

class UIslandNunchuckDefaultComboCapability : UHazeChildCapability
{
 	default CapabilityTags.Add(n"Nunchuck");
 	default DebugCategory = n"Nunchuck";

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UPlayerIslandNunchuckUserComponent MeleeComp;
	UPlayerTargetablesComponent TargetContainer;
	UPlayerMovementComponent MoveComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerSprintComponent SprintComp;
 	USteppingMovementData Movement;

	AHazePlayerCharacter Player;
	UIslandNunchuckDefaultComboMoveAsset ActiveMove;
	UIslandNunchuckTargetableComponent Target;
	bool bStartedIdling = false;
	
	FIslandNunchuckAnimationData ActiveAnimationData;
	FIslandNunchuckRootMotion ActiveAnimationRootMotion;
	float PendingDeltaTime = 0;
	float ActivePlayLength = 0;

	float CurrentSpeed = 0.0;
	FVector CurrentMovementDirection = FVector::ZeroVector;

	FIslandNunchuckPendingImpactData PendingImpacts;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Player);
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandNunchuckDefaultComboMoveActivation& Activation) const
	{
		if(MeleeComp.NoValidTargetMoveAssets.Num() == 0)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.5))
			return false;
		
		if(MeleeComp.IsNunchuckInputBlocked())
			return false;

		if(MeleeComp.IsInBlockedActionWindow())
			return false;

		// We need to have a primary target to trigger
		auto PrimTarget = TargetContainer.GetPrimaryTarget(UIslandNunchuckTargetableComponent);
		if(PrimTarget == nullptr)
			return false;

		// Player grounded type
		TArray<EIslandNunchuckGroundedSettingsType> ValidPlayerGroundedTypes;
		if(MoveComp.IsOnAnyGround())
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
		else
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);

		// Targetable component required grounded type
		TArray<EIslandNunchuckGroundedSettingsType> ValidTargetableTypes;
		if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::Grounded)
		{
			ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::Flying)
		{
			ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::AirAndGround)
		{
			if(MoveComp.IsOnAnyGround())
				ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
			else	
				ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::MoveCompStatus)
		{
			auto TargetMoveComp = UHazeMovementComponent::Get(PrimTarget.Owner);
			if(TargetMoveComp != nullptr)
			{
				if(TargetMoveComp.IsOnAnyGround())
					ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
				else	
					ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
			}
			else
			{
				devError(f"Target point on {PrimTarget.Owner} has type 'MoveCompStatus' but no movement component");
			}
		}
		
		// Travers Type
		TArray<EIslandNunchuckTriggerSettingsType> ValidTraversTypes;
		if(PrimTarget.bCanTraversToTarget)
			ValidTraversTypes.Add(EIslandNunchuckTriggerSettingsType::True);
		else
			ValidTraversTypes.Add(EIslandNunchuckTriggerSettingsType::False);

		// Stationary Type
		TArray<EIslandNunchuckTriggerSettingsType> ValidStationaryTypes;
		if(PrimTarget.bTargetIsStationary)
			ValidStationaryTypes.Add(EIslandNunchuckTriggerSettingsType::True);
		else
			ValidStationaryTypes.Add(EIslandNunchuckTriggerSettingsType::False);
		
		EIslandNunchuckMoveAssetPriority HighestPriority = EIslandNunchuckMoveAssetPriority::Default;

		const float TargetDistance = MeleeComp.GetAttackDistanceToTarget(PrimTarget);
		TArray<UIslandNunchuckDefaultComboMoveAsset> FinalAvailableAsset;
		for(auto It : MeleeComp.DefaultComboMoveAssets)
		{
			if(It == nullptr)
				continue;

			if(It.Priority < HighestPriority)
				continue;

			if(!MeleeComp.ValidateComboChain(It))
				continue;

			if(It.bValidatePlayerGroundedType && !ValidPlayerGroundedTypes.Contains(It.PlayerGroundedType))
				continue;

			if(It.bValidateTargetableGroundedType && !ValidTargetableTypes.Contains(It.TargetableGroundedType))
				continue;

			if(It.bValidateRequiresTraversalToBe && !ValidTraversTypes.Contains(It.RequiresTraversalToBe))
				continue;
			
			if(It.bValidateRequiresStationaryTargetToBe && !ValidStationaryTypes.Contains(It.RequiresStationaryTargetToBe))
				continue;

			if(TargetDistance < It.RequiredDistanceToTarget.Min && It.RequiredDistanceToTarget.Min >= 0)
				continue;

			if(TargetDistance > It.RequiredDistanceToTarget.Max && It.RequiredDistanceToTarget.Max >= 0)
				continue;

			if(!PrimTarget.ValidateTags(It.Tags))
				continue;

			if(It.Priority > HighestPriority)
			{
				FinalAvailableAsset.Reset();
				HighestPriority = It.Priority;
			}
			
			FinalAvailableAsset.Add(It);
		}

		if(FinalAvailableAsset.Num() == 0)
			return false;

		int ActivationIndex = -1;
		UIslandNunchuckDefaultComboMoveAsset Move;
		while(true)
		{
			ActivationIndex = Math::RandRange(0, FinalAvailableAsset.Num() - 1);
			Move = FinalAvailableAsset[ActivationIndex];
			
			// Make sure we dont activate the same move if we have more to pick from
			if(FinalAvailableAsset.Num() == 1 || !MeleeComp.WasMoveRecentlyActivated(Move))
				break;
		}

		Activation.Target = PrimTarget;
		Activation.Move = FinalAvailableAsset[Math::RandRange(0, FinalAvailableAsset.Num() - 1)];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveMove == nullptr)
			return true;

		if(Target == nullptr)
			return true;

		if(!ActiveAnimationData.IsValidForPlayer())
			return true;

		if(ActivePlayLength + PendingDeltaTime >= ActiveAnimationData.GetMovePlayLength() || bStartedIdling)
		{
			if(!MoveComp.MovementInput.IsNearlyZero())
		 		return true;

			if(WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
				return true;

			if(!ActiveMove.Animation.Settle.IsValidForPlayer())
				return true;
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandNunchuckDefaultComboMoveActivation Activation)
	{
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		CurrentMovementDirection = Player.ActorForwardVector;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);	
		ActiveMove = Activation.Move;
		Target = Activation.Target;

		MeleeComp.SetActiveMove(ActiveMove, Target, this);
		ActivateAnimation();

		PendingImpacts.Setup(ActiveMove, ActiveMove.Animation.Move);	
		MeleeComp.PreviousAnimationOvershotTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(ActiveAnimationData.PlayerAnimation.Sequence != nullptr)
			MeleeComp.PlayerOwner.StopSlotAnimationByAsset(ActiveAnimationData.PlayerAnimation.Sequence);

		if(ActiveAnimationData.WeaponAnimation.Sequence != nullptr)
			MeleeComp.Weapon.StopSlotAnimationByAsset(ActiveAnimationData.WeaponAnimation.Sequence);

		if(!bStartedIdling)
		{
			float OvershotTime = Math::Min(ActiveAnimationData.GetMovePlayLength() - (ActivePlayLength + PendingDeltaTime), 0);
			MeleeComp.PreviousAnimationOvershotTime = Math::Abs(OvershotTime);
		}
		
		ActiveAnimationData = FIslandNunchuckAnimationData();
		Player.ClearActorTimeDilation(this);
		MeleeComp.Weapon.ClearActorTimeDilation(this);
		MeleeComp.ClearActiveMove(this);
		ActiveMove = nullptr;
		bStartedIdling = false;
		ActivePlayLength = 0;
		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PendingDeltaTime = DeltaTime;
	}


 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaTime)
	{
		ActivePlayLength += DeltaTime;
		PendingImpacts.Update(ActivePlayLength, MeleeComp);

		if(ActivePlayLength >= ActiveAnimationData.GetMovePlayLength())
		{
			if(!bStartedIdling)
			{	
				ActivateSettleAnimation();
			}
		}
		
		if(MoveComp.PrepareMove(Movement))
		{
			if(MoveComp.IsOnAnyGround())
			{
				ApplyGroundedMovement(DeltaTime);
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
			}
			else
			{
				ApplyAirMovement(DeltaTime);
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
			}
		}
	}

	void ActivateAnimation()
	{
		const FIslandNunchuckAnimationData PrevActiveAnimationData = ActiveAnimationData;

		bStartedIdling = false;
		ActivePlayLength = 0;
		ActiveAnimationData = ActiveMove.Animation.Move;

		// Validate that we have an animtion and a valid length
		check(ActiveAnimationData.IsValidForPlayer());

		FHazeSlotAnimSettings Settings;
		Settings.PlayRate = ActiveAnimationData.GetPlayRateToReachExpectedAnimationLength();
		Settings.BlendType = EHazeBlendType::BlendType_Inertialization;
		Settings.BlendTime = Settings.BlendTime = ActiveMove.GetBlendInTime();

		FVector DeltaToTarget = Target.GetOwner().GetActorLocation() - Player.GetActorLocation();
		//FVector DirToTarget = DeltaToTarget.GetSafeNormal();
		float DistanceToTarget = DeltaToTarget.Size();
		DistanceToTarget = DistanceToTarget - Target.KeepDistance - MoveComp.GetCollisionCapsuleRadius() - 10;

		if(DistanceToTarget > 0 && Target.bCanTraversToTarget)
			ActiveAnimationRootMotion.Init(ActiveAnimationData, FVector::ForwardVector * DistanceToTarget);
		else
			ActiveAnimationRootMotion.Clear();

		if(ActiveAnimationData.IsValidForPlayerAndWeapon())
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.PlaySlotAnimation(ActiveAnimationData.WeaponAnimation.Sequence, Settings);
		}
		else
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.StopSlotAnimationByAsset(PrevActiveAnimationData.WeaponAnimation.Sequence);
		}
	}

	// UFUNCTION(CrumbFunction)
	// void CrumbActivateMove(FIslandNunchuckDefaultComboMoveActivation Activation)
	// {
	// 	if(IsActive())
	// 	{
	// 		ActiveMove = Activation.Move;
	// 		Target = Activation.Target;
	// 		MeleeComp.SetActiveMove(ActiveMove, this);
	// 		ActivateAnimation(0);	
	// 	}
	// }

	// UFUNCTION(CrumbFunction)
	// void CrumbActivateAnimation(int ComboIndex)
	// {
	// 	if(IsActive())
	// 	{
	// 		ActivateAnimation(ComboIndex);
	// 	}
	// }

	void ActivateSettleAnimation()
	{
		ActivePlayLength = 0;

		FIslandNunchuckAnimationData IdleAnimationData = ActiveMove.Animation.Settle;
		if(IdleAnimationData.GetMovePlayLength() <= 0)
		{
			MeleeComp.PlayerOwner.StopSlotAnimationByAsset(ActiveAnimationData.PlayerAnimation.Sequence);
			MeleeComp.Weapon.StopSlotAnimationByAsset(ActiveAnimationData.WeaponAnimation.Sequence);
			ActiveAnimationData = FIslandNunchuckAnimationData();
			return;
		}

		const FIslandNunchuckAnimationData PrevActiveAnimationData = ActiveAnimationData;
		bStartedIdling = true;
		ActiveAnimationData = IdleAnimationData;
		ActiveAnimationRootMotion.Init(ActiveAnimationData);

		FHazeSlotAnimSettings Settings;
		Settings.PlayRate = ActiveAnimationData.GetPlayRateToReachExpectedAnimationLength();
		Settings.BlendType = EHazeBlendType::BlendType_Inertialization;
		Settings.BlendTime = 0;
		Settings.StartTime = 0;

		if(ActiveAnimationData.IsValidForPlayerAndWeapon())
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.PlaySlotAnimation(ActiveAnimationData.WeaponAnimation.Sequence, Settings);
		}
		else
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.StopSlotAnimationByAsset(PrevActiveAnimationData.WeaponAnimation.Sequence);
		}
	}

	void ApplyGroundedMovement(float DeltaTime)
	{
		if(HasControl())
		{	
			// Setup the target direction
			FVector TargetDirection = Target.GetOwner().GetActorLocation() - Player.GetActorLocation();
			TargetDirection = TargetDirection.VectorPlaneProject(MoveComp.WorldUp);
			if(TargetDirection.IsNearlyZero())
				TargetDirection = MoveComp.GetTargetFacingRotationQuat().ForwardVector;
			else
				TargetDirection.Normalize();

			const float Alpha = Math::Min(ActiveDuration / 0.15, 1);
			CurrentMovementDirection = CurrentMovementDirection.SlerpVectorTowardsAroundAxis(TargetDirection, MoveComp.WorldUp, Alpha);
	
			// Update new velocity
			float InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier * 2;
			CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), 0, DeltaTime, InterpSpeed);
			FVector HorizontalVelocity = CurrentMovementDirection * CurrentSpeed;

			bool bHasFoundRootMotion = false;
			FVector WorldDelta = FVector::ZeroVector;
			if(ActiveAnimationData.IsValidForPlayer() && ActiveAnimationRootMotion.bHasRootmotion)
			{
				bHasFoundRootMotion = true;
				FVector LocalDelta = ActiveAnimationRootMotion.GetLocalRootMotionAmount(ActivePlayLength);

				FRotator DeltaOrientation = FRotator::MakeFromXZ(CurrentMovementDirection, MoveComp.WorldUp);
				WorldDelta = DeltaOrientation.RotateVector(LocalDelta);
			}
	
			if(bHasFoundRootMotion)
			{
				HorizontalVelocity = WorldDelta.GetSafeNormal() * HorizontalVelocity.Size();
				Movement.AddDeltaWithCustomVelocity(WorldDelta, HorizontalVelocity);

				FRotator WantedRotation = WorldDelta.ToOrientationRotator();
				WantedRotation = Math::RInterpTo(Player.GetActorRotation(), WantedRotation, DeltaTime, 10);
				Movement.SetRotation(WantedRotation);
			}
			else
			{
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);
			}

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();

			// Force the player of edges if we are not 
			//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));
		}
		// Remote update
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}
	}

	void ApplyAirMovement(float DeltaTime)
	{
		if(HasControl())
		{
			float TargetMovementSpeed = FloorMotionComp.Settings.MaximumSpeed + 150.0;
			if (SprintComp.IsSprintToggled())
				TargetMovementSpeed = SprintComp.Settings.MaximumSpeed;

			TargetMovementSpeed *= MoveComp.MovementSpeedMultiplier;

			float InterpSpeed;
			if(MoveComp.HorizontalVelocity.Size() > TargetMovementSpeed)
				InterpSpeed = 450.0;
			else
				InterpSpeed = Math::Lerp(450.0, 1500.0, MoveComp.MovementInput.Size());

			FVector TargetSpeed = MoveComp.MovementInput * TargetMovementSpeed;
			FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, InterpSpeed);

			Movement.AddHorizontalVelocity(HorizontalVelocity);
			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();				
			Movement.AddPendingImpulses();

			/*
				Calculate how fast the player should rotate when falling at fast speeds
			*/
			const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
			const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

			const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
			Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}
	}

}

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Owner);
// 		TargetContainer = UPlayerTargetablesComponent::Get(Owner);
// 		MoveComp = UPlayerMovementComponent::Get(Owner);
// 		Movement = MoveComp.SetupSteppingMovementData();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnRemoved()
// 	{
// 		Player.ClearLocomotionFeatureBundleByInstigator(this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FPlayerIslandNunchuckComboStandardActivation& Activation) const
// 	{
// 		// if(!MeleeComp.HasWeaponEquiped())
// 		// 	return false;

// 		// if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
// 		// 	return false;

// 		// Activation.Target = TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 		// Activation.Variation = MeleeComp.CurrentMoveVariationStartingAtZero;
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		// if(MeleeComp.CurrentActiveMoveTimeUnClamped >= MeleeComp.CurrentActiveMoveTimeMax + MeleeComp.CurrentActiveSettleTime)
// 		// 	return true;

// 		// if(bAttackAnimationIsDone)
// 		// {
// 		// 	if(!MoveComp.MovementInput.IsNearlyZero())
// 		// 		return true;

// 		// 	if(MoveComp.HasMovedThisFrame())
// 		// 		return true;
// 		// }
		
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FPlayerIslandNunchuckComboStandardActivation Activation)
// 	{
// 		MeleeComp.Weapon.ShowWeapon();
// 		ActivateMove(Activation);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		// MeleeComp.CurrentMoveType = EPlayerScifiMeleeMoveType::MAX;
// 		// MeleeComp.CurrentMoveComboIndexStartingAtZero = 0;
// 		// MeleeComp.CurrentMoveVariationStartingAtZero = 0;
// 		// MeleeComp.CurrentActiveMoveTimeUnClamped = 0;
// 		// MeleeComp.CurrentActiveMovePlayRate = 0;
// 		// MeleeComp.LastTargetDirection = FVector::ZeroVector;
// 		// MeleeComp.AvailableSingleHits = 0;
// 		// MeleeComp.PrimaryTarget = nullptr;
// 		// MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::None;
// 		// bHasTargetLocation = false;
			
// 		// Player.ClearActorTimeDilation(this);
// 		// MeleeComp.Weapon.ClearActorTimeDilation(this);
		
// 		// MeleeComp.Weapon.HideWeapon();
// 	}

// 	void ActivateMove(FPlayerIslandNunchuckComboStandardActivation Activation)
// 	{
// 		// NoTargetGroundedMoveSpeedMultiplier = 1.0;
// 		// bIsFirstFrame = true;
// 		// bTriggerNextAttackAtEndOfThisAttack = false;
// 		// bAttackAnimationIsDone = false;
// 		// bHasTargetLocation = false;

// 		// // Initialize target
// 		// MeleeComp.CurrentMoveType = EPlayerScifiMeleeMoveType::Standard;
// 		// MeleeComp.PrimaryTarget = Activation.Target;
// 		// bHasReachedTarget = false;
// 		// MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::None;

// 		// MeleeComp.PerformedImpacts.Empty();
// 		// AccumulateRootMotionMovement = FVector::ZeroVector;

// 		// if(MeleeComp.PrimaryTarget != nullptr)
// 		// {
// 		// 	MeleeComp.LastTargetDirection = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();

// 		// 	float ForwardBackwardAmount = MeleeComp.LastTargetDirection.DotProductLinear(Player.ActorForwardVector);
// 		// 	if(ForwardBackwardAmount >= 0.5)
// 		// 	{
// 		// 		if(MeleeComp.LastTargetDirection.DotProduct(Player.ActorForwardVector) >= 0)
// 		// 			MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::InFront;
// 		// 		else
// 		// 			MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::Behind;
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		if(MeleeComp.LastTargetDirection.DotProduct(Player.ActorRightVector) >= 0)
// 		// 			MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::ToTheRight;
// 		// 		else
// 		// 			MeleeComp.PrimaryTargetRelativeDirection = EScifiMeleeTargetableDirection::ToTheLeft;
// 		// 	}
// 		// }
// 		// else
// 		// {
// 		// 	MeleeComp.LastTargetDirection = FVector::ZeroVector;
// 		// }

// 		// // Initialize attack data
// 		// MeleeComp.CurrentMoveVariationStartingAtZero = Activation.Variation;
// 		// MeleeComp.CurrentMoveComboIndexStartingAtZero = Activation.Index;
// 		// CurrentActiveAttackData = MeleeComp.GetFinalizedStandardMoveData(MeleeComp.PrimaryTargetRelativeDirection);

// 		// MeleeComp.CurrentActiveMoveTimeUnClamped = 0;
// 		// MeleeComp.CurrentActiveMoveTimeMax = CurrentActiveAttackData.Length;
// 		// MeleeComp.CurrentActiveSettleTime = CurrentActiveAttackData.Settle;

// 		// if(MeleeComp.PrimaryTarget != nullptr && CurrentActiveAttackData.CanTravelToTarget == EPlayerScifiMeleeTravelToTargetType::True)
// 		// {
// 		// 	IntialDistanceToTarget = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).Size();
// 		// 	KeepDistanceToTarget = MeleeComp.GetKeepDistanceRange(CurrentActiveAttackData, MeleeComp.PrimaryTarget);
// 		// 	IntialDistanceToTarget = Math::Max(0.0, IntialDistanceToTarget - KeepDistanceToTarget); 
// 		// 	if(IntialDistanceToTarget < KINDA_SMALL_NUMBER)
// 		// 	{
// 		// 		ReachTarget();
// 		// 	}
// 		// }
// 		// else
// 		// {
			
// 		// 	MeleeComp.CurrentActiveMovePlayRate = 0.5;
// 		// }

// 		// Player.TriggerEffectEvent(n"ScifiMelee.Attack");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		// // Update combo input
// 		// if(!bIsFirstFrame 
// 		// && !bTriggerNextAttackAtEndOfThisAttack
// 		// && IsInComboInputWindow() 
// 		// && WasActionStarted(ActionNames::PrimaryLevelAbility))
// 		// {
// 		// 	bTriggerNextAttackAtEndOfThisAttack = true;
// 		// }
		
// 		// // Handle delta time
// 		// {	
// 		// 	MeleeComp.IncreaseMoveTime(DeltaTime);
// 		// 	const float TimeDilationMul = GetTimeDilationMultiplier();
// 		// 	Player.SetActorTimeDilation(TimeDilationMul, this);
// 		// 	MeleeComp.Weapon.SetActorTimeDilation(TimeDilationMul, this);
// 		// }

// 		// if(MeleeComp.CurrentActiveMoveTimeUnClamped >= CurrentActiveAttackData.Length * MeleeComp.CurrentActiveMovePlayRate)
// 		// {
// 		// 	if(bTriggerNextAttackAtEndOfThisAttack)
// 		// 	{
// 		// 		FPlayerIslandNunchuckComboStandardActivation Activation;
// 		// 		Activation.Target = TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 		// 		Activation.Index = MeleeComp.CurrentMoveComboIndexStartingAtZero + 1;	
// 		// 		if(Activation.Index >= MeleeComp.StandardMoves[MeleeComp.CurrentMoveVariationStartingAtZero].Moves.Num())
// 		// 		{
// 		// 			Activation.Index = 0;
// 		// 			Activation.Variation = MeleeComp.CurrentMoveVariationStartingAtZero + 1;
// 		// 			if(Activation.Variation >= MeleeComp.StandardMoves.Num())
// 		// 			{
// 		// 				Activation.Variation = 0.0;
// 		// 			}
// 		// 		}
			
// 		// 		Player.TriggerEffectEvent(n"ScifiMelee.AttackCompleted");
// 		// 		ActivateMove(Activation);
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		//MeleeComp.CurrentMoveVariationStartingAtZero = 0;
// 		// 		MeleeComp.CurrentMoveComboIndexStartingAtZero = -1;
// 		// 	}
// 		// }
		
// 		// // Update current move
// 		// {
// 		// 	MeleeComp.CurrentActiveMovePlayRate = Math::FInterpConstantTo(MeleeComp.CurrentActiveMovePlayRate, 1.0, DeltaTime, 10.0);

// 		// 	if(MoveComp.PrepareMove(Movement))
// 		// 	{	
// 		// 		FQuat TargetRotation = Owner.GetActorQuat();

// 		// 		// Update facing
// 		// 		if(MeleeComp.PrimaryTarget != nullptr && MeleeComp.PrimaryTarget.bCanTraversToTarget)
// 		// 		{
// 		// 			TargetLocation = MeleeComp.PrimaryTarget.WorldLocation;
// 		// 			bHasTargetLocation = true;
// 		// 		}

// 		// 		if(bHasTargetLocation && !bHasReachedTarget)
// 		// 		{
// 		// 			FVector DeltaToLocation = (TargetLocation - Player.ActorLocation);
// 		// 			DeltaToLocation = DeltaToLocation.VectorPlaneProject(MoveComp.WorldUp);

// 		// 			FVector DirToLocation = DeltaToLocation;
// 		// 			if(!DirToLocation.IsNearlyZero(1.0))
// 		// 			{
// 		// 				DirToLocation.Normalize();
// 		// 				TargetRotation = DirToLocation.ToOrientationQuat();
// 		// 			}
		
// 		// 			// Apply moveto target information
// 		// 			if(!bIsFirstFrame && IntialDistanceToTarget > 0)
// 		// 			{	
// 		// 				FVector TotalMovementDelta = FVector::ForwardVector * IntialDistanceToTarget;

// 		// 				// The target might be moving towards us
// 		// 				if(DeltaToLocation.Size() < KeepDistanceToTarget)
// 		// 				{
// 		// 					ReachTarget();
// 		// 				}
// 		// 				else
// 		// 				{
// 		// 					bool bHasFoundRootMotion = false;
// 		// 					TArray<FHazePlayingAnimationData> Animations;
// 		// 					Player.Mesh.GetCurrentlyPlayingAnimations(Animations);

// 		// 					FVector LocalDelta = FVector::ZeroVector;
// 		// 					for (const FHazePlayingAnimationData& AnimData : Animations)
// 		// 					{	
// 		// 						LocalDelta += AnimData.Sequence.GetDeltaMoveForMoveRatio(
// 		// 							AccumulateRootMotionMovement, 
// 		// 							Math::Min(MeleeComp.CurrentActiveMoveTimeUnClamped, MeleeComp.CurrentActiveMoveTimeMax), 
// 		// 							TotalMovementDelta, 
// 		// 							CurrentActiveAttackData.Length * MeleeComp.CurrentActiveMovePlayRate);

// 		// 						FHazeLocomotionTransform RootMotion;
// 		// 						if(AnimData.Sequence.ExtractTotalRootMotion(RootMotion))
// 		// 						{
// 		// 							bHasFoundRootMotion = !RootMotion.DeltaTranslation.IsNearlyZero();
// 		// 						}
// 		// 					}	

// 		// 					if(bHasFoundRootMotion)
// 		// 					{
// 		// 						FVector DeltaToAdd = TargetRotation.RotateVector(LocalDelta);
// 		// 						Movement.AddDeltaWithCustomVelocity(DeltaToAdd, FVector::ZeroVector);
// 		// 					}
// 		// 					else
// 		// 					{
// 		// 						// If the animation dont provide any root motion, we snap to the target
// 		// 						Movement.AddDeltaWithCustomVelocity(DirToLocation * IntialDistanceToTarget, FVector::ZeroVector);
// 		// 						ReachTarget();
// 		// 					}	
// 		// 				}
// 		// 			}	
// 		// 		}
// 		// 		else if(!MeleeComp.LastTargetDirection.IsNearlyZero())
// 		// 		{
// 		// 			TargetRotation = MeleeComp.LastTargetDirection.ToOrientationQuat();
// 		// 		}
// 		// 		else if(!MoveComp.MovementInput.IsNearlyZero(0.1))
// 		// 		{
// 		// 			TargetRotation = MoveComp.MovementInput.ToOrientationQuat();
// 		// 			if(MoveComp.IsOnAnyGround())
// 		// 			 {
// 		// 				// Reduce velocity over time during the attack, making it feel a little bit more like a dash
// 		// 				NoTargetGroundedMoveSpeedMultiplier = Math::Max(NoTargetGroundedMoveSpeedMultiplier-DeltaTime*4.0, 0);
						
// 		// 				Movement.AddHorizontalVelocity(MoveComp.MovementInput * CurrentActiveAttackData.NoTargetGroundedMoveSpeed * NoTargetGroundedMoveSpeedMultiplier);
// 		// 			}

// 		// 			else
// 		// 			{
// 		// 				Movement.AddOwnerHorizontalVelocity();
// 		// 			}

// 		// 		}

// 		// 		Movement.AddGravityAcceleration();
// 		// 		Movement.AddOwnerVerticalVelocity();

// 		// 		if(MeleeComp.BlockMovementRotation == 0 && !bIsFirstFrame)
// 		// 			Movement.SetRotation(Math::QInterpConstantTo(Owner.GetActorQuat(), TargetRotation, DeltaTime, 20.0));
				
// 		// 		MoveComp.ApplyMoveAndRequestLocomotion(Movement, CurrentActiveAttackData.AnimationRequestTag);
// 		// 		// if(!bAttackAnimationIsDone)
// 		// 		// 	MoveComp.ApplyMoveAndRequestLocomotion(Movement, CurrentActiveAttackData.AnimationRequestTag);
// 		// 		// else
// 		// 		// 	MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
// 		// 	}

// 		// 	if(MeleeComp.AvailableMultiHits > 0)
// 		// 	{	
// 		// 		for(UScifiMeleeTargetableComponent ImpactTarget : MeleeComp.PotentialTargets)
// 		// 		{
// 		// 			auto TargetComp = USciFiMeleeImpactResponseComponent::Get(ImpactTarget.Owner);
// 		// 			if(TargetComp != nullptr && MeleeComp.ValidateMultiHitComponent(TargetComp))
// 		// 			{
// 		// 				MeleeComp.PerformHitOnImpactComponent(TargetComp, CurrentActiveAttackData.Damage, n"Standard");
// 		// 			}
// 		// 		}
// 		// 	}
// 		// 	else if(MeleeComp.AvailableSingleHits > 0)
// 		// 	{
// 		// 		MeleeComp.AvailableSingleHits--;
// 		// 		if(MeleeComp.PrimaryTarget != nullptr)
// 		// 		{
// 		// 			auto TargetComp = USciFiMeleeImpactResponseComponent::Get(MeleeComp.PrimaryTarget.Owner);
// 		// 			if(TargetComp != nullptr && MeleeComp.ValidateSingleHitComponent(TargetComp))
// 		// 			{
// 		// 				Player.TriggerEffectEvent(n"ScifiMelee.AttackImpact", FIslandNunchuckAttackImpactData(TargetComp.Owner));
// 		// 				MeleeComp.PerformHitOnImpactComponent(TargetComp, CurrentActiveAttackData.Damage, n"Standard");
// 		// 			} 		
// 		// 		}
// 		// 	}

// 		// 	// Clear the prim target if we cant target it.
// 		// 	if(MeleeComp.PrimaryTarget != nullptr 
// 		// 		&& MeleeComp.PrimaryTarget.IsDisabled())
// 		// 	{
// 		// 		MeleeComp.PrimaryTarget = nullptr;
// 		// 	}

// 		// 	if(!bAttackAnimationIsDone 
// 		// 		&& MeleeComp.CurrentActiveMoveTimeUnClamped >= MeleeComp.CurrentActiveMoveTimeMax * MeleeComp.CurrentActiveMovePlayRate)
// 		// 	{				
// 		// 		Player.TriggerEffectEvent(n"ScifiMelee.AttackCompleted");
// 		// 		bAttackAnimationIsDone = true;
// 		// 		MeleeComp.CurrentMoveComboIndexStartingAtZero = 0;
// 		// 		MeleeComp.CurrentMoveType = EPlayerScifiMeleeMoveType::MAX;
// 		// 		Player.SetActorVelocity(FVector::ZeroVector);
// 		// 	}

// 		// 	bIsFirstFrame = false;
// 		// }
// 	}

// 	void ReachTarget()
// 	{
// 		// bHasReachedTarget = true;
// 		// //MeleeComp.bCanUpdateTargets = true;
// 		// MeleeComp.ActionEpiCenter.Enable(Player.ActorLocation);
// 	}

// 	void GetStandardMoveComboWindow(float& OutStartTime, float& OutEndTime) const
// 	{
// 		// const FScifiMeleeComboWindow& WindowToUse = CurrentActiveAttackData.ComboWindow;
// 		// if(WindowToUse.bFromStart)
// 		// {
// 		// 	OutStartTime = 0;
// 		// 	OutEndTime = Math::Max(WindowToUse.Value, 0.0);
// 		// }
// 		// else
// 		// {
// 		// 	OutStartTime = Math::Max(CurrentActiveAttackData.Length - WindowToUse.Value, 0.0);
// 		// 	OutEndTime = Math::Max(CurrentActiveAttackData.Length, 0.0);
// 		// }
// 	}

// 	bool IsInComboInputWindow() const
// 	{
// 		// if(CurrentActiveAttackData.ComboWindow.bEntireMove)
// 		// 	return true;

// 		// float WindowMin = 0, WindowMax = 0;
// 		// GetStandardMoveComboWindow(WindowMin, WindowMax);

// 		// if(MeleeComp.CurrentActiveMoveTimeUnClamped < WindowMin)
// 		// 	return false;

// 		// if(MeleeComp.CurrentActiveMoveTimeUnClamped > WindowMax)
// 		// 	return false;

// 		return true;
// 	}

// 	float GetTimeDilationMultiplier() const
// 	{
// 		return 1;
// 		// if(MeleeComp.CurrentActiveMoveTimeMax <= KINDA_SMALL_NUMBER)
// 		// 	return 1.0;

// 		// float Alpha = Math::Min(MeleeComp.CurrentActiveMoveTimeUnClamped / MeleeComp.CurrentActiveMoveTimeMax, 1.0);
// 		// return CurrentActiveAttackData.TimeDilationModifier.GetFloatValue(Alpha, 1.0);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnLogActive(FTemporalLog TemporalLog)
// 	{
// 		// TemporalLog.Value("ActiveMove", MeleeComp.CurrentMoveType);
// 		// TemporalLog.Value("MoveIndex", MeleeComp.GetActiveComboIndex());
// 	}
// }