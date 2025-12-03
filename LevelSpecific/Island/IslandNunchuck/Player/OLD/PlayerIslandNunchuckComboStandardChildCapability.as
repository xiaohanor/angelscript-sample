
// struct FPlayerIslandNunchuckComboStandardActivation
// {
// 	UScifiMeleeTargetableComponent Target;
// 	int Index = 0;
// 	int Variation = 0;
// }

// UCLASS(NotBlueprintable)
// class UPlayerIslandNunchuckComboStandardChildCapability : UHazeChildCapability
// {
// 	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

// 	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

// 	UPlayerIslandNunchuckUserComponent MeleeComp;
// 	UPlayerMovementComponent MoveComp;
// 	UPlayerTargetablesComponent TargetContainer;
// 	USteppingMovementData Movement;
// 	AHazePlayerCharacter Player;

// 	int MoveIndex = 0;
// 	EPlayerScifiMeleeStandardMoveType MoveType;
// 	FScifiMeleeStandardMoveData MoveData;

// 	//FIslandNunchuckTravelToTargetData ActiveTravelData;
// 	const float TravelDeltaTimeModifier = 0.5;
// 	//bool bHasForcedLerp = false;
	
// 	//UScifiMeleeTargetableComponent PrimaryTarget;
// 	bool bIsFirstFrame = false;
// 	//float TotalMovementTime = 0.0;
// 	float DistanceToTarget = 0.0;
// 	float CurrentTravelTime = 0.0;

// 	FVector AccumulatedAnimMovement = FVector::ZeroVector;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Owner);
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		MoveComp = UPlayerMovementComponent::Get(Owner);
// 		Movement = MoveComp.SetupSteppingMovementData();
// 		TargetContainer = UPlayerTargetablesComponent::Get(Owner);


// 		// If we add more moves to the combo capability, we also need to update the enum
// 		MoveIndex = MeleeComp.TotalComboCount++;
// 		MoveType = EPlayerScifiMeleeStandardMoveType(MoveIndex);

// 		MoveData = MeleeComp.GetFinalizedStandardMoveData();
// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FPlayerIslandNunchuckComboStandardActivation& Activation) const
// 	{
// 		if(!MeleeComp.HasNormalMoveInput())
// 			return false;

// 		if(!MeleeComp.HasWeaponEquiped())
// 			return false;
	
// 		Activation.Target = TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 		Activation.Variation = MeleeComp.CurrentMoveVariationStartingAtZero;
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		// We have press input in a combo window
// 		if(MeleeComp.HasNormalMoveInput())
// 		{
// 			if(DistanceToTarget <= 0.0)
// 				return true;
// 			// if(!ActiveTravelData.IsActive())
// 			// 	return true;
// 		}
		
// 		if(MeleeComp.CurrentActiveMoveTime >= MoveData.Length)
// 			return true;

// 		if(!MeleeComp.HasWeaponEquiped())
// 			return true;

// 		return false;
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FPlayerIslandNunchuckComboStandardActivation Activation)
// 	{
// 		#if EDITOR
// 		// Update in the editor since the data asset might change
// 		// But only on activation
// 		MeleeComp.CurrentMoveComboIndexStartingAtZero = MoveIndex;
// 		MoveData = MeleeComp.GetFinalizedStandardMoveData();
// 		#endif

// 		MeleeComp.Weapon.ShowWeapon();

// 		MeleeComp.InitializeMove(EPlayerScifiMeleeMoveType::Standard, Activation.Variation, MoveIndex, MoveData.Length, MoveData.TimeDilationModifier);
// 		MeleeComp.TraversToTargetAlpha = 1;

// 		MeleeComp.PrimaryTarget = Activation.Target;

// 		if(MeleeComp.PrimaryTarget != nullptr && MoveData.CanTravelToTarget == EPlayerScifiMeleeTravelToTargetType::True)
// 		{
// 			//TotalMovementTime = MoveData.ReachTargetTime.GetFinalizedValue(MeleeComp.GetReachTargetTime());
// 			//DistanceToTarget = MeleeComp.GetReachTargetRange(PrimaryTarget);
// 			DistanceToTarget = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).Size();

// 			float PlayerSize = Player.CapsuleComponent.ScaledCapsuleRadius;
// 			float TargetSize = UCapsuleComponent::Get(MeleeComp.PrimaryTarget.Owner).ScaledCapsuleRadius;
// 			DistanceToTarget = Math::Max(0.0, DistanceToTarget - PlayerSize - TargetSize - 10); // A little less to not stand outside
// 			if(DistanceToTarget < KINDA_SMALL_NUMBER)
// 			{
// 				ReachTarget();
// 			}

// 			MeleeComp.PrimaryTarget.ApplyInteractionTime();
// 			MeleeComp.LastTargetDirection = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();

// 			// ActiveTravelData = MeleeComp.GetTravelToTargetData(
// 			// 	PrimaryTarget.WorldLocation, 
// 			// 	MeleeComp.GetReachTargetRange(PrimaryTarget),
// 			// 	100, // Keep Distance
// 			// 	TimeToReachTarget);
// 		}
// 		else
// 		{
// 			MeleeComp.TraversToTargetAlpha = 0;		
// 			MeleeComp.CurrentActiveMovePlayRate = TravelDeltaTimeModifier;
// 		}

// 		AccumulatedAnimMovement = FVector::ZeroVector;
// 		CurrentTravelTime = 0.0;

// 		//Player.BlockCapabilities(n"NunchuckPickTarget", this);

// 		// MeleeComp.HasActiveMoveRotation = MoveComp.MovementInput != FVector::ZeroVector || MeleeComp.BufferedMovementInput != FVector::ZeroVector;
// 		// if(MeleeComp.HasActiveMoveRotation)
// 		// {
// 		// 	if(MoveComp.MovementInput != FVector::ZeroVector)
// 		// 	{
// 		// 		MeleeComp.ActiveMoveRotation = MoveComp.MovementInput;
// 		// 	}
// 		// 	else if(MeleeComp.BufferedMovementInput != FVector::ZeroVector)
// 		// 	{
// 		// 		MeleeComp.ActiveMoveRotation = MeleeComp.BufferedMovementInput;
// 		// 		MeleeComp.BufferedMovementInput = FVector::ZeroVector;
// 		// 	}
// 		// }

// 		// if(ActiveTravelData.DistanceToStandAtLocation < 10 
// 		// 	|| ActiveTravelData.DotToTarget < 0.5 
// 		// 	|| ActiveTravelData.DistanceToTarget < ActiveTravelData.DistanceToStandAtLocation
// 		// 	|| ActiveTravelData.TimeToReachTarget <= 0)
// 		// 	{
// 		// 		ActiveTravelData.Invalidate();
// 		// 		MeleeComp.TraversToTargetAlpha = 1.0;
// 		// 	}
// 		MeleeComp.bCanUpdateTargets = false;

// 		bIsFirstFrame = true;
// 		Player.TriggerEffectEvent(n"ScifiMelee.Attack");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		MeleeComp.bCanUpdateTargets = true;

// 		// We need to clean up before the next combo happens
// 		// if(MeleeComp.CurrentMoveType != EPlayerScifiMeleeMoveType::Charge)
// 		// {
// 		// 	MeleeComp.CurrentMoveType = EPlayerScifiMeleeMoveType::MAX;
// 		// 	MeleeComp.CurrentMoveComboIndexStartingAtZero = 0;
// 		// }
// 	//	MeleeComp.bAnimNotifyTriggerTravelToTarget = false;

// 		//ActiveTravelData.Invalidate();
// 		//bHasForcedLerp = false;
// 		Player.ClearActorTimeDilation(this);
// 		MeleeComp.Weapon.ClearActorTimeDilation(this);
		
// 		Player.TriggerEffectEvent(n"ScifiMelee.AttackCompleted");

// 		MeleeComp.Weapon.HideWeapon();
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{	
// 			FQuat TargetRotation = Owner.GetActorQuat();
// 			bool bCanIncreasePlayRate = true;

// 			// if(MoveComp.MovementInput != FVector::ZeroVector)
// 			// {
// 			// 	MeleeComp.BufferedMovementInput = MoveComp.MovementInput;
// 			// }

// 			// If we have a target, we lock that
// 			// if(MeleeComp.PrimaryTarget != nullptr)
// 			// {
// 			// 	MeleeComp.bCanUpdateTargets = false;
// 			// }

// 			// if(!bIsFirstFrame)
// 			// {
// 			// 	CurrentTravelTime += DeltaTime;
// 			// }

// 			// FVector Direction = MeleeComp.ActiveMoveLocation - Owner.ActorLocation;
// 			// Direction.Normalize();
// 			// float Angle = MoveComp.MovementInput.GetAngleDegreesTo(Direction);
// 			// bool PermitActiveRotation = (!MeleeComp.HasActiveMoveLocation || Angle > 60);

// 			// if(MeleeComp.HasActiveMoveRotation && PermitActiveRotation)
// 			// {
// 			// 	TargetRotation = MeleeComp.ActiveMoveRotation.ToOrientationQuat();
// 			// }
// 			// else if(MeleeComp.HasActiveMoveLocation)
// 			// {	
// 			// 	// Face the correct way
// 			// 	TargetRotation = MeleeComp.GetFaceTargetDirection(MeleeComp.ActiveMoveLocation).ToOrientationQuat();	
		
// 			// 	// if(TravelData.IsActive() && MeleeComp.TraversToTargetAlpha < 1.0 && MeleeComp.CanTravelToTarget(MoveData.CanTravelToTarget, true))
// 			// 	// {	
// 			// 	// 	bCanIncreasePlayRate = false;

// 			// 	// 	// Make sure we dont lerp before we know that the input is not a hold
// 			// 	// 	if(ActiveDuration >= MeleeComp.TriggerChargeWindow || !MeleeComp.bHasHoldInput || bHasForcedLerp)
// 			// 	// 	{
// 			// 	// 		bHasForcedLerp = true;
// 			// 	// 		const float TravelAlpha = TravelData.GetTravelAlpha();

// 			// 	// 		// Make sure we always end up at the end position
// 			// 	// 		if(TravelAlpha >= 1.0)
// 			// 	// 			MeleeComp.TraversToTargetAlpha = TravelAlpha;
// 			// 	// 		else
// 			// 	// 			MeleeComp.TraversToTargetAlpha = MoveData.GetReachTargetTimeAlphaModifier(TravelAlpha);

// 			// 	// 		MeleeComp.CurrentActiveMovePlayRate = Math::EaseIn(TravelDeltaTimeModifier, 1.0, MeleeComp.TraversToTargetAlpha, 2.0);
// 			// 	// 		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TravelData.GetTravelToLocation(MeleeComp.TraversToTargetAlpha), FVector::ZeroVector, EMovementDeltaType::HorizontalPlane);
// 			// 	// 		TravelData.Tick(DeltaTime);	
// 			// 	// 	}
// 			// 	// 	else if(MeleeComp.MovementBreakAmount >= 0)
// 			// 	// 	{
// 			// 	// 		FVector CurrentVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(2000.0);
// 			// 	// 		CurrentVelocity = Math::VInterpTo(CurrentVelocity, FVector::ZeroVector, DeltaTime, MeleeComp.MovementBreakAmount);
// 			// 	// 		Movement.AddHorizontalVelocity(CurrentVelocity);
// 			// 	// 	}		
// 			// 	// }
// 			// }
			
// 			// if(!MeleeComp.ActiveMove)
// 			if(bCanIncreasePlayRate)
// 			{
// 				MeleeComp.CurrentActiveMovePlayRate = Math::FInterpConstantTo(MeleeComp.CurrentActiveMovePlayRate, 1.0, DeltaTime, 10.0);
// 			}

// 			// Update facing
// 			if(MeleeComp.PrimaryTarget != nullptr)
// 			{
// 				FVector DeltaToLocation = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation);
// 				DeltaToLocation = DeltaToLocation.VectorPlaneProject(MoveComp.WorldUp);

// 				FVector DirToLocation = DeltaToLocation;
// 				if(!DirToLocation.IsNearlyZero(1.0))
// 				{
// 					DirToLocation.Normalize();
// 					TargetRotation = DirToLocation.ToOrientationQuat();
// 				}
// 				else
// 				{
// 					ReachTarget();
// 				}

// 				// Apply moveto target information
// 				if(!bIsFirstFrame && DistanceToTarget > 0)
// 				{	
// 					bool bHasFoundRootMotion = false;
// 					TArray<FHazePlayingAnimationData> Animations;
// 					Player.Mesh.GetCurrentlyPlayingAnimations(Animations);

// 					FVector LocalDelta = FVector::ZeroVector;
// 					for (const FHazePlayingAnimationData& AnimData : Animations)
// 					{
// 						FVector TotalMovementDelta = FVector::ForwardVector * DistanceToTarget;
// 						LocalDelta += AnimData.Sequence.GetDeltaMoveForMoveRatio(
// 							AccumulatedAnimMovement, 
// 							CurrentTravelTime, 
// 							TotalMovementDelta, 
// 							MoveData.Length * MeleeComp.CurrentActiveMovePlayRate);

// 						FHazeLocomotionTransform RootMotion;
// 						if(AnimData.Sequence.ExtractTotalRootMotion(RootMotion))
// 						{
// 							bHasFoundRootMotion = !RootMotion.DeltaTranslation.IsNearlyZero();
// 						}
// 					}	

// 					if(bHasFoundRootMotion)
// 					{
// 						FVector DeltaToAdd = TargetRotation.RotateVector(LocalDelta);
// 						Movement.AddDelta(DeltaToAdd);
// 					}
// 					else
// 					{
// 						// If the animation dont provide any root motion, we snap to the target
// 						Movement.AddDelta(DirToLocation * DistanceToTarget);
// 						ReachTarget();
// 					}
					
			
// 				// 	if(MeleeComp.ActiveMoveNotifies.Num() > 0)
// 				// 	{
// 				// 		float StepSpeed = 60.0;
// 				// 		float ActiveSpeedDistance = 250.0;
// 				// 		float ActiveSpeed = 250.0;

// 				// 		FVector TargetVelocity = Owner.GetActorForwardVector() * StepSpeed;
// 				// 		if(MeleeComp.HasActiveMoveRotation && PermitActiveRotation)
// 				// 		{
// 				// 			TargetVelocity = MeleeComp.ActiveMoveRotation * StepSpeed;
// 				// 		}
// 				// 		else if(MeleeComp.HasActiveMoveLocation)
// 				// 		{
// 				// 			TargetVelocity = MeleeComp.ActiveMoveLocation - Owner.ActorLocation;
// 				// 			TargetVelocity.Normalize();
// 				// 			TargetVelocity *= StepSpeed;
// 				// 		}

// 				// 		if(MeleeComp.HasActiveMoveLocation && !Owner.ActorLocation.IsWithinDist(MeleeComp.ActiveMoveLocation, ActiveSpeedDistance))
// 				// 		{
// 				// 			TargetVelocity.Normalize();
// 				// 			TargetVelocity *= ActiveSpeed;
// 				// 		}

// 				// 		if(MeleeComp.MovementBreakAmount >= 0 && MoveComp.HorizontalVelocity.Size() > TargetVelocity.Size())
// 				// 		{
// 				// 			// FVector CurrentVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(2000.0);
// 				// 			// CurrentVelocity = Math::VInterpTo(CurrentVelocity, FVector::ZeroVector, DeltaTime, MeleeComp.MovementBreakAmount * 10);
// 				// 			// Movement.AddHorizontalVelocity(CurrentVelocity);
// 				// 			TargetVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(2000.0);
// 				// 			TargetVelocity = Math::VInterpTo(TargetVelocity, FVector::ZeroVector, DeltaTime, MeleeComp.MovementBreakAmount * 10);
// 				// 		}	
// 				// 		else
// 				// 		{
// 				// 			// TODO, add rootmotion	
// 				// 			// Movement.AddDeltaWithCustomVelocity(TargetVelocity * DeltaTime, TargetVelocity);
// 				// 			// Movement.AddHorizontalVelocity(TargetVelocity);
// 				// 			// TargetRotation = MoveComp.FinalizeRotation(Player.GetViewTransform().GetRotation(), MoveComp.GetWorldUp());
// 				// 		}	
						
// 				// 		FActiveMoveNotifyData MoveNotifyData = MeleeComp.ActiveMoveNotifies.Last();
// 				// 		float Speed = 1.0;
// 				// 		if(MoveNotifyData.SpeedCurve.NumKeys > 0)
// 				// 		{
// 				// 			float Alpha = MeleeComp.CurrentActiveMoveTime / MeleeComp.CurrentActiveMoveTimeMax;
// 				// 			Speed = MoveNotifyData.SpeedCurve.GetFloatValue(Alpha, 1.0);
// 				// 		}
// 				// 		Movement.AddHorizontalVelocity(TargetVelocity * Speed);
// 				// 	}			
// 				}	
// 			}

			

// 			// if(MeleeComp.ActiveMoveTarget == nullptr || MeleeComp.ActiveMoveTarget.TargetableType == EScifiMeleeTargetableType::Grounded)
// 			// {
// 			// 	Movement.AddGravityAcceleration();
// 			// 	Movement.AddOwnerVerticalVelocity();
// 			// }

// 			Movement.AddGravityAcceleration();
// 			Movement.AddOwnerVerticalVelocity();

// 			Movement.SetRotation(Math::QInterpConstantTo(Owner.GetActorQuat(), TargetRotation, DeltaTime, 20.0));
// 			MoveComp.ApplyMove(Movement);
// 		}

// 		MeleeComp.IncreaseMoveTime(DeltaTime);
// 		Player.SetActorTimeDilation(MeleeComp.GetTimeDilationMultiplier(), this);
// 		MeleeComp.Weapon.SetActorTimeDilation(MeleeComp.GetTimeDilationMultiplier(), this);
		
// 		if(MeleeComp.CanHitMultipleImpactComponents())
// 		{	
// 			for(UScifiMeleeTargetableComponent ImpactTarget : MeleeComp.PotentialTargets)
// 			{
// 				auto TargetComp = USciFiMeleeImpactResponseComponent::Get(ImpactTarget.Owner);
// 				if(TargetComp != nullptr && MeleeComp.CanHitImpactComponent(TargetComp))
// 				{
// 					MeleeComp.PerformHitOnImpactComponent(TargetComp, MoveData.Damage, n"Standard");
// 					//MeleeComp.bCanUpdateTargets = true;
// 				}
// 			}
// 		}
// 		else if(MeleeComp.CanHitOneImpactComponent())
// 		{
// 			if(MeleeComp.PrimaryTarget != nullptr)
// 			{
// 				auto TargetComp = USciFiMeleeImpactResponseComponent::Get(MeleeComp.PrimaryTarget.Owner);
// 				if(TargetComp != nullptr && MeleeComp.CanHitImpactComponent(TargetComp))
// 				{
// 					MeleeComp.PerformHitOnImpactComponent(TargetComp, MoveData.Damage, n"Standard");
// 					//MeleeComp.bCanUpdateTargets = true;
// 				} 		
// 			}
// 		}

// 		if(Player.Mesh.CanRequestLocomotion())
// 		{
// 			Player.Mesh.RequestLocomotion(MoveData.AnimationRequestTag, this);
// 		}


// 		CurrentTravelTime += DeltaTime;
// 		bIsFirstFrame = false;
// 	}

// 	void ReachTarget()
// 	{
// 		DistanceToTarget = 0.0;

// 		if(!MeleeComp.ActionEpiCenter.bIsValid)
// 		{
// 			MeleeComp.ActionEpiCenter.bIsValid = true;
// 			MeleeComp.ActionEpiCenter.Location = Player.ActorLocation;
// 			MeleeComp.ActionEpiCenter.CreationTime = Time::GameTimeSeconds;
// 		}
// 	}
// }