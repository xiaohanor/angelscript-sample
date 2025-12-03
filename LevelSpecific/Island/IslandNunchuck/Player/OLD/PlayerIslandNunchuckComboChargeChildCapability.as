// struct FPlayerIslandNunchuckComboChargeActivation
// {
// 	UScifiMeleeTargetableComponent Target;
// }

// class UPlayerIslandNunchuckComboChargeChildCapability : UHazeChildCapability
// {
//  	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

// 	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

// 	UPlayerIslandNunchuckUserComponent MeleeComp;
// 	UPlayerMovementComponent MoveComp;
// 	UPlayerTargetablesComponent TargetContainer;
// 	USteppingMovementData Movement;
// 	AHazePlayerCharacter Player;

// 	EPlayerScifiMeleeStandardMoveType MoveType;
// 	int MoveIndex = 0;
// 	FScifiMeleeChargeMoveData MoveData;

// 	//FPlayerScifiTravelToTargetData TravelData;
// 	const float TravelDeltaTimeModifier = 0.5;

// 	uint LastDeactivatedFrame = 0;

// 	//UScifiMeleeTargetableComponent PrimaryTarget;
// 	bool bIsFirstFrame = false;
// 	float TotalMovementTime = 0.0;
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
		
// 		MoveIndex = MeleeComp.TotalChargeCount++;
// 		MoveType = EPlayerScifiMeleeStandardMoveType(MoveIndex);

// 		SetupMoveData();
// 	}

// 	void SetupMoveData()
// 	{
// 		MoveData = MeleeComp.GetFinalizedChargeMoveData();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FPlayerIslandNunchuckComboChargeActivation& Activation) const
// 	{
// 		if(!MeleeComp.HasChargeMoveInput())
// 			return false;

// 		if(MeleeComp.CurrentStandardMoveComboIndexStartingAtZero != MoveIndex)
// 			return false;

// 		if(!MeleeComp.HasWeaponEquiped())
// 			return false;

// 		if(LastDeactivatedFrame >= Time::GetFrameNumber())
// 			return false;
		
// 		Activation.Target = TargetContainer.GetPrimaryTarget(UScifiMeleeTargetableComponent);
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(ActiveDuration < MoveData.ChargeupTime && !MeleeComp.HasChargeMoveInput())
// 			return true;

// 		if(MeleeComp.HasNormalMoveInput())
// 			return true;

// 		// Exit early if player is giving move input. TODO: Move to settings file
// 		float ExitEarlyTime = 1.5;
// 		bool ExitEarly = MeleeComp.CurrentActiveMoveTime >= MoveData.Length - ExitEarlyTime;
// 		if(MoveComp.MovementInput != FVector::ZeroVector && ExitEarly)
// 			return true;

// 		if(MeleeComp.bHasInput && ExitEarly)
// 			return true;

// 		if(MeleeComp.CurrentActiveMoveTime >= MoveData.Length)
// 			return true;

// 		if(!MeleeComp.HasWeaponEquiped())
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FPlayerIslandNunchuckComboChargeActivation Activation)
// 	{	
// 		#if EDITOR
// 		// Update in the editor since the data asset might change
// 		// But only on activation
// 		MeleeComp.CurrentStandardMoveComboIndexStartingAtZero = MoveIndex;
// 		SetupMoveData();
// 		#endif

// 		MeleeComp.Weapon.ShowWeapon();

// 		MeleeComp.InitializeMove(EPlayerScifiMeleeMoveType::Charge, MoveIndex, MoveData.Length, MoveData.TimeDilationModifier);
// 		MeleeComp.CurrentActiveMoveChargeTimeMax = MoveData.ChargeupTime;
// 		MeleeComp.TraversToTargetAlpha = 1;

// 		// MeleeComp.TargetLocationData.bHasRotation = MoveComp.MovementInput != FVector::ZeroVector;
// 		// if(MeleeComp.HasActiveMoveRotation)
// 		// {
// 		// 	MeleeComp.ActiveMoveRotation = MoveComp.MovementInput;
// 		// }

// 		// if(MeleeComp.HasActiveMoveLocation && MeleeComp.CanTravelToTarget(MoveData.CanTravelToTarget, false))
// 		// {
// 		// 	float TimeToReachTarget = MoveData.ReachTargetTime.GetFinalizedValue(MeleeComp.GetReachTargetTime());
// 		// 	// float KeepDistance = MeleeComp.GetKeepDistanceRange(MoveData, MeleeComp.ActiveMoveTarget);
			
// 		// 	TravelData = MeleeComp.GetTravelToTargetData(
// 		// 		MeleeComp.ActiveMoveLocation, 
// 		// 		100, 
// 		// 		TimeToReachTarget);

// 		// 	if(TravelData.DistanceToStandAtLocation < 10 
// 		// 	|| TravelData.DotToTarget < 0.5 
// 		// 	|| TravelData.DistanceToTarget < TravelData.DistanceToStandAtLocation
// 		// 	|| TravelData.TimeToReachTarget <= 0)
// 		// 	{
// 		// 		TravelData.Invalidate();
// 		// 		MeleeComp.TraversToTargetAlpha = 1.0;
// 		// 	}
// 		// 	else
// 		// 	{
// 		// 		MeleeComp.TraversToTargetAlpha = 0;	
// 		// 		MeleeComp.CurrentActiveMovePlayRate = TravelDeltaTimeModifier;
// 		// 	}
// 		// }
// 		// else
// 		// {
// 		// 	Player.SetMovementFacingDirection(MoveComp.FinalizeRotation(Player.GetViewTransform().GetRotation(), MoveComp.GetWorldUp()));
// 		// }

// 		MeleeComp.PrimaryTarget = Activation.Target;

// 		if(MeleeComp.PrimaryTarget != nullptr && MoveData.CanTravelToTarget == EPlayerScifiMeleeTravelToTargetType::True)
// 		{
// 			//TotalMovementTime = MoveData.ReachTargetTime.GetFinalizedValue(MeleeComp.GetReachTargetTime());
// 			//DistanceToTarget = MeleeComp.GetReachTargetRange(PrimaryTarget);
// 			DistanceToTarget = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).Size();

// 			float PlayerSize = Player.CapsuleComponent.ScaledCapsuleRadius;
// 			float TargetSize = UCapsuleComponent::Get(MeleeComp.PrimaryTarget.Owner).ScaledCapsuleRadius;
// 			DistanceToTarget = Math::Max(0.0, DistanceToTarget - PlayerSize - TargetSize - 10); // A little less to not stand outside

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
// 		bIsFirstFrame = true;
// 		MeleeComp.bCanUpdateTargets = false;

// 		//Player.BlockCapabilities(n"NunchuckPickTarget", this);
// 		Player.TriggerEffectEvent(n"ScifiMelee.AreaAttack");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		//Player.UnblockCapabilities(n"NunchuckPickTarget", this);
// 		MeleeComp.bCanUpdateTargets = true;
// 		MeleeComp.Weapon.HideWeapon();

// 		MeleeComp.CurrentMoveType = EPlayerScifiMeleeMoveType::MAX;
// 		MeleeComp.CurrentStandardMoveComboIndexStartingAtZero = 0;
// 		//MeleeComp.bAnimNotifyTriggerTravelToTarget = false;

// 		//TravelData.Invalidate();
// 		Player.ClearActorTimeDilation(this);
// 		MeleeComp.Weapon.ClearActorTimeDilation(this);

// 		LastDeactivatedFrame = Time::GetFrameNumber();

// 		Player.TriggerEffectEvent(n"ScifiMelee.AreaAttackCompleted");
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{	
// 			FQuat TargetRotation = Owner.GetActorQuat();
// 			bool bCanIncreasePlayRate = true;

// 			if(bCanIncreasePlayRate)
// 			{
// 				MeleeComp.CurrentActiveMovePlayRate = Math::FInterpConstantTo(MeleeComp.CurrentActiveMovePlayRate, 1.0, DeltaTime, 10.0);
// 			}

// 			if(MeleeComp.PrimaryTarget != nullptr)
// 			{
// 				MeleeComp.bCanUpdateTargets = false;
// 			}

// 			// Update facing
// 			if(MeleeComp.PrimaryTarget != nullptr)
// 			{
// 				FVector DirToLocation = (MeleeComp.PrimaryTarget.WorldLocation - Player.ActorLocation).GetSafeNormal();
// 				DirToLocation = DirToLocation.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
// 				if(!DirToLocation.IsNearlyZero())
// 					TargetRotation = DirToLocation.ToOrientationQuat();
// 			}

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
// 			// 	// 	const float TravelAlpha = TravelData.GetTravelAlpha();

// 			// 	// 	// Make sure we always end up at the end position
// 			// 	// 	if(TravelAlpha >= 1.0)
// 			// 	// 		MeleeComp.TraversToTargetAlpha = TravelAlpha;
// 			// 	// 	else
// 			// 	// 		MeleeComp.TraversToTargetAlpha = MoveData.GetReachTargetTimeAlphaModifier(TravelAlpha);

// 			// 	// 	MeleeComp.CurrentActiveMovePlayRate = Math::EaseIn(TravelDeltaTimeModifier, 1.0, MeleeComp.TraversToTargetAlpha, 2.0);
// 			// 	// 	Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TravelData.GetTravelToLocation(MeleeComp.TraversToTargetAlpha), FVector::ZeroVector, EMovementDeltaType::HorizontalPlane);
// 			// 	// 	TravelData.Tick(DeltaTime);		
// 			// 	// }
// 			// }
			
// 			// if(!MeleeComp.ActiveMove)
// 			// {
// 				// TODO, add rootmotion
// 				// Movement.AddDeltaWithCustomVelocity(Owner.GetActorForwardVector() * DeltaTime * 30, FVector::ZeroVector);
// 				// TargetRotation = MoveComp.FinalizeRotation(Player.GetViewTransform().GetRotation(), MoveComp.GetWorldUp());

// 				// if(MeleeComp.ActiveMoveNotifies.Num() > 0)
// 				// {
// 				// 	FVector TargetVelocity = Owner.GetActorForwardVector() * 0;
// 				// 	if(MeleeComp.HasActiveMoveRotation && PermitActiveRotation)
// 				// 	{
// 				// 		TargetVelocity = MeleeComp.ActiveMoveRotation * 0;
// 				// 	}
// 				// 	// else if(MeleeComp.HasActiveMoveLocation)
// 				// 	// {
// 				// 	// 	TargetVelocity = MeleeComp.ActiveMoveLocation - Owner.ActorLocation;
// 				// 	// 	TargetVelocity.Normalize();
// 				// 	// 	TargetVelocity *= 1000;
// 				// 	// }

// 				// 	if(MeleeComp.MovementBreakAmount >= 0 && MoveComp.HorizontalVelocity.Size() > TargetVelocity.Size())
// 				// 	{
// 				// 		// FVector CurrentVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(1000.0);
// 				// 		// CurrentVelocity = Math::VInterpTo(CurrentVelocity, FVector::ZeroVector, DeltaTime, MeleeComp.MovementBreakAmount * 10);
// 				// 		// Movement.AddHorizontalVelocity(CurrentVelocity);
// 				// 		TargetVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(1000.0);
// 				// 		TargetVelocity = Math::VInterpTo(TargetVelocity, FVector::ZeroVector, DeltaTime, MeleeComp.MovementBreakAmount * 10);
// 				// 	}	
// 				// 	else
// 				// 	{
// 				// 		// TODO, add rootmotion	
// 				// 		// Movement.AddDeltaWithCustomVelocity(TargetVelocity * DeltaTime, TargetVelocity);
// 				// 		// Movement.AddHorizontalVelocity(TargetVelocity);
// 				// 		// TargetRotation = MoveComp.FinalizeRotation(Player.GetViewTransform().GetRotation(), MoveComp.GetWorldUp());
// 				// 	}

// 				// 	FActiveMoveNotifyData MoveNotifyData = MeleeComp.ActiveMoveNotifies.Last();
// 				// 	float Speed = 1.0;
// 				// 	if(MoveNotifyData.SpeedCurve.NumKeys > 0)
// 				// 	{
// 				// 		float Alpha = MeleeComp.CurrentActiveMoveTime / MeleeComp.CurrentActiveMoveTimeMax;
// 				// 		Speed = MoveNotifyData.SpeedCurve.GetFloatValue(Alpha, 1.0);
// 				// 	}

// 				// 	Movement.AddHorizontalVelocity(TargetVelocity * Speed);
// 				// }
// 			// }	
		
// 			// if(MeleeComp.ActiveMoveTarget == nullptr || MeleeComp.ActiveMoveTarget.TargetableType == EScifiMeleeTargetableType::Grounded)
// 			// {
// 			// 	Movement.AddGravityAcceleration();
// 			// 	Movement.AddOwnerVerticalVelocity();
// 			// }

// 			// Apply moveto target information
// 			if(MeleeComp.PrimaryTarget != nullptr && !bIsFirstFrame)
// 			{	
// 				TArray<FHazePlayingAnimationData> Animations;
// 				Player.Mesh.GetCurrentlyPlayingAnimations(Animations);

// 				FVector LocalDelta = FVector::ZeroVector;
// 				for (const FHazePlayingAnimationData& AnimData : Animations)
// 				{
// 					FVector TotalMovementDelta = FVector::ForwardVector * DistanceToTarget;
// 					LocalDelta += AnimData.Sequence.GetDeltaMoveForMoveRatio(
// 						AccumulatedAnimMovement, 
// 						CurrentTravelTime, 
// 						TotalMovementDelta, 
// 						MoveData.Length * MeleeComp.CurrentActiveMovePlayRate);
// 				}	

// 				FVector DeltaToAdd = TargetRotation.RotateVector(LocalDelta);
// 				Movement.AddDelta(DeltaToAdd);		
// 			}

// 			Movement.AddGravityAcceleration();
// 			Movement.AddOwnerVerticalVelocity();

// 			if(bCanIncreasePlayRate)
// 			{
// 				MeleeComp.CurrentActiveMovePlayRate = Math::FInterpConstantTo(MeleeComp.CurrentActiveMovePlayRate, 1.0, DeltaTime, 10.0);
// 			}
			
// 			Movement.SetRotation(Math::QInterpConstantTo(Owner.GetActorQuat(), TargetRotation, DeltaTime, 40.0));		
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
// 					MeleeComp.PerformHitOnImpactComponent(TargetComp, MoveData.Damage, n"Charge");
// 					MeleeComp.bCanUpdateTargets = false;
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
// 					MeleeComp.PerformHitOnImpactComponent(TargetComp, MoveData.Damage, n"Charge");
// 					MeleeComp.bCanUpdateTargets = false;
// 				} 		
// 			}
// 		}

// 		if(Player.Mesh.CanRequestLocomotion())
// 		{
// 			Player.Mesh.RequestLocomotion(n"NunchucksAreaAttack", this);
// 		}
// 	}

// }