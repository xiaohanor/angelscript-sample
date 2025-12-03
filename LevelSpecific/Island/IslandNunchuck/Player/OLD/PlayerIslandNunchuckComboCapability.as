// struct FPlayerIslandNunchuckComboStandardActivation
// {
// 	UIslandNunchuckTargetableComponent Target;
// 	int Index = 0;
// 	int Variation = 0;
// }

// class UPlayerIslandNunchuckComboCapability : UHazePlayerCapability
// {
// 	default CapabilityTags.Add(n"ScifiMelee");
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);
// 	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

// 	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
// 	default CapabilityTags.Add(BlockedWhileIn::WallRun);
// 	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
// 	default CapabilityTags.Add(BlockedWhileIn::Dash);
	
// 	default DebugCategory = n"ScifiMelee";

// 	default TickGroup = EHazeTickGroup::ActionMovement;
// 	default TickGroupOrder = 50;
// 	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 20);

// 	UPlayerIslandNunchuckUserComponent MeleeComp;
// 	UPlayerTargetablesComponent TargetContainer;
// 	UPlayerMovementComponent MoveComp;

// 	USteppingMovementData Movement;
// 	//FScifiMeleeStandardMoveData CurrentActiveAttackData;

// 	float IntialDistanceToTarget = 0.0;
// 	float KeepDistanceToTarget = 0.0;
// 	bool bAttackAnimationIsDone = false;
// 	bool bHasReachedTarget = false;
// 	bool bIsFirstFrame = true;
// 	bool bTriggerNextAttackAtEndOfThisAttack = false;
// 	float NoTargetGroundedMoveSpeedMultiplier = 1.0;

// 	FVector AccumulateRootMotionMovement = FVector::ZeroVector;	
// 	FVector TargetLocation = FVector::ZeroVector;
// 	bool bHasTargetLocation = false;

// 	// UFUNCTION(BlueprintOverride)
// 	// UHazeCompoundNode GenerateCompound()
// 	// {
// 	// 	return
// 	// 	UHazeCompoundSelector()
// 	// 	// .Try( // Charges can interup the regular combos
// 	// 	// 	UHazeCompoundStatePicker()
// 	// 	// 	.State(UPlayerIslandNunchuckComboChargeChildCapability())
// 	// 	// 	.State(UPlayerIslandNunchuckComboChargeChildCapability())
// 	// 	// 	.State(UPlayerIslandNunchuckComboChargeChildCapability())
// 	// 	// )
// 	// 	.Try(
// 	// 		UHazeCompoundSequence() // Combos are performed in sequence as long as an input is performed
// 	// 		.Then(UPlayerIslandNunchuckComboStandardChildCapability())
// 	// 		.Then(UPlayerIslandNunchuckComboStandardChildCapability())
// 	// 		.Then(UPlayerIslandNunchuckComboStandardChildCapability())
// 	// 	)
// 	// 	;
// 	// }

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