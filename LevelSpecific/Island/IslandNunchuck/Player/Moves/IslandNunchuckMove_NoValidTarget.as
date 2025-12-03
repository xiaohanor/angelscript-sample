
enum EIslandNunchuckNoValidTargetTriggerType
{
	// We have no enemies at all
	NoVisibleEnemies,

	// We have enemies, but no one we can reach
	NoValidEnemies
}


class UIslandNunchuckNoValidTargetMoveAsset : UIslandNunchuckMoveAssetBase
{	
	// Respond to why we dont have a valid enemy target
	UPROPERTY(Category = "Settings")
	EIslandNunchuckNoValidTargetTriggerType TriggerType = EIslandNunchuckNoValidTargetTriggerType::NoVisibleEnemies;
	
	// Respond to the players grounded status
	UPROPERTY(Category = "Settings")
	EIslandNunchuckGroundedSettingsType PlayerGroundedType = EIslandNunchuckGroundedSettingsType::Grounded; 

	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidateMovementInput = false;

	// Respond to the players input amount
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidateMovementInput"))
	EIslandNunchuckTriggerSettingsType HasMovementInput = EIslandNunchuckTriggerSettingsType::True;

	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
	FIslandNunchuckAnimationWithSettleData Animation;

	UPROPERTY(Category = "Animation|Settings", meta = (EditCondition = "!bIsPartOfComboChain || ComboChainIndex==1"))
	float BlendTime = 0;

	float GetBlendInTime() const
	{
		if(bIsPartOfComboChain && ComboChainIndex != 1)
			return 0;

		return Math::Max(BlendTime, 0);
	}
}

struct FIslandNunchuckNoValidTargetMoveActivation
{
	UIslandNunchuckNoValidTargetMoveAsset Move;
}

class UIslandNunchuckNoValidTargetMoveCapability : UHazeChildCapability
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
	UIslandNunchuckNoValidTargetMoveAsset ActiveMove;
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
	bool ShouldActivate(FIslandNunchuckNoValidTargetMoveActivation& Activation) const
	{
		if(MeleeComp.NoValidTargetMoveAssets.Num() == 0)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.5))
			return false;

		if(MeleeComp.IsNunchuckInputBlocked())
			return false;

		if(MeleeComp.IsInBlockedActionWindow())
			return false;

		// We have a primary target so we should trigger a attack move instead
		auto PrimeTarget = TargetContainer.GetPrimaryTarget(UIslandNunchuckTargetableComponent);
		if(PrimeTarget != nullptr)
			return false;
		
		// Validate the visibility type required
		TArray<EIslandNunchuckNoValidTargetTriggerType> ValidTriggerTypes;
		ValidTriggerTypes.Add(EIslandNunchuckNoValidTargetTriggerType::NoValidEnemies);

		TArray<UTargetableComponent> VisibleTargetables;
		TargetContainer.GetVisibleTargetables(UIslandNunchuckTargetableComponent, VisibleTargetables);
		if(VisibleTargetables.Num() == 0)
			ValidTriggerTypes.Add(EIslandNunchuckNoValidTargetTriggerType::NoVisibleEnemies);
		
		// Player grounded type
		TArray<EIslandNunchuckGroundedSettingsType> ValidPlayerGroundedTypes;
		if(MoveComp.IsOnAnyGround() || MeleeComp.PendingGroundImpact.IsValidBlockingHit())
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
		else
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);

		// Validate the grounded type of the player required
		TArray<EIslandNunchuckGroundedSettingsType> ValidGroundedTypes;
		if(!MoveComp.IsOnAnyGround() && !MeleeComp.PendingGroundImpact.IsValidBlockingHit())
			ValidGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
		else
			ValidGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);

		TArray<EIslandNunchuckTriggerSettingsType> MovementInputTypes;
		if(MoveComp.Velocity.SizeSquared() > KINDA_SMALL_NUMBER ||  MoveComp.MovementInput.SizeSquared() > KINDA_SMALL_NUMBER)
			MovementInputTypes.Add(EIslandNunchuckTriggerSettingsType::True);
		else
			MovementInputTypes.Add(EIslandNunchuckTriggerSettingsType::False);

		EIslandNunchuckMoveAssetPriority HighestPriority = EIslandNunchuckMoveAssetPriority::Default;

		TArray<UIslandNunchuckNoValidTargetMoveAsset> FinalAvailableAsset;
		for(auto It : MeleeComp.NoValidTargetMoveAssets)
		{
			if(It == nullptr)
				continue;

			if(It.Priority < HighestPriority)
				continue;

			if(!ValidTriggerTypes.Contains(It.TriggerType))
				continue;
				
			if(!ValidGroundedTypes.Contains(It.PlayerGroundedType))
				continue;
			
			if(It.bValidateMovementInput && !MovementInputTypes.Contains(It.HasMovementInput))
				continue;
		
			if(!MeleeComp.ValidateComboChain(It))
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
		UIslandNunchuckNoValidTargetMoveAsset Move;
		while(true)
		{
			ActivationIndex = Math::RandRange(0, FinalAvailableAsset.Num() - 1);
			Move = FinalAvailableAsset[ActivationIndex];
			
			// Make sure we dont activate the same move if we have more to pick from
			if(FinalAvailableAsset.Num() == 1 || !MeleeComp.WasMoveRecentlyActivated(Move))
				break;
		}
			
		Activation.Move = Move;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveMove == nullptr)
			return true;

		if(!ActiveAnimationData.IsValidForPlayer())
			return true;

		if(MoveComp.HasMovedThisFrame())
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
	void OnActivated(FIslandNunchuckNoValidTargetMoveActivation Activation)
	{
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		CurrentMovementDirection = Player.ActorForwardVector;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
			
		ActiveMove = Activation.Move;
		MeleeComp.SetActiveMove(ActiveMove, nullptr, this);

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
		Settings.bPauseAtEnd = true;
		Settings.PlayRate = ActiveAnimationData.GetPlayRateToReachExpectedAnimationLength();
		Settings.BlendType = EHazeBlendType::BlendType_Inertialization;
		Settings.BlendTime = ActiveMove.GetBlendInTime();
		if(!ActiveMove.IsValidComboChain() || ActiveMove.IsFirstInComboChain())
			Settings.StartTime = 0;
		else
			Settings.StartTime = MeleeComp.PreviousAnimationOvershotTime;
		
		// // Setup the potential root motion movement
		// float InputSize = MoveComp.MovementInput.Size();
		// const float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
		// ExpectedMoveAmount = InputSize > 0 ? FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha) * MoveComp.MovementSpeedMultiplier : 0;
		// ExpectedMoveAmount * ActiveAnimationData.MovePlayLength;
		//ExpectedMoveAmount = FVector::ZeroVector;

		ActiveAnimationRootMotion.Clear();

		if(MoveComp.Velocity.IsNearlyZero())
		{
			ActiveAnimationRootMotion.Init(ActiveAnimationData);
		}

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

	void ActivateSettleAnimation()
	{
		ActivePlayLength = 0;

		if(ActiveMove == nullptr)
			return;

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
			FVector TargetDirection = MoveComp.MovementInput;
			float InputSize = MoveComp.MovementInput.Size();

			// While on edges, we force the player of them.
			if(MoveComp.HasUnstableGroundContactEdge())
			{
				const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
				float InputAgainstEdgeAlpha = TargetDirection.DotProduct(MoveComp.GroundContact.Normal);
				if(InputAgainstEdgeAlpha < 0.7)
				{
					TargetDirection = (MoveComp.GroundContact.Normal + (TargetDirection * 3)).GetSafeNormal();
					InputSize = 0.1;
				}
				else if(InputSize < 0.1)
				{
					TargetDirection = MoveComp.GroundContact.Normal;
					InputSize = 1;
				}
			}
			
			if(TargetDirection.IsNearlyZero())
				TargetDirection = MoveComp.GetTargetFacingRotationQuat().ForwardVector;

			CurrentMovementDirection = Math::VInterpConstantTo(CurrentMovementDirection, TargetDirection, DeltaTime, 15.0).GetSafeNormal();

			// Update new velocity
			float InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier * 2;
			CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), 0, DeltaTime, InterpSpeed);
			FVector HorizontalVelocity = CurrentMovementDirection * CurrentSpeed;

			bool bHasFoundRootMotion = false;
			FVector LocalDelta = FVector::ZeroVector;
			if(ActiveAnimationData.IsValidForPlayer() && ActiveAnimationRootMotion.bHasRootmotion)
			{
				bHasFoundRootMotion = true;
				LocalDelta = ActiveAnimationRootMotion.GetLocalRootMotionAmount(ActivePlayLength);
			}
	
			if(bHasFoundRootMotion && !CurrentMovementDirection.IsNearlyZero())
			{
				FVector DeltaToAdd = Player.GetActorRotation().RotateVector(LocalDelta);
				Movement.AddDeltaWithCustomVelocity(DeltaToAdd, FVector::ZeroVector);
			}
			else
			{
				Movement.AddHorizontalVelocity(HorizontalVelocity);
			}

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();

			// Force the player of edges if we are not 
			//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

			// Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
			Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);
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