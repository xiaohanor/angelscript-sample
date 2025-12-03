class UDragonSwordCombatSprintAttackCapability : UHazePlayerCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::GameplayAction);

	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttack);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordSprintAttack);

	// default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	// default TickGroup = EHazeTickGroup::ActionMovement;
	// default TickGroupOrder = 85;
	// default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30, 1);

	// UDragonSwordUserComponent SwordComp;
	// UDragonSwordCombatUserComponent CombatComp;

	// UPlayerTargetablesComponent TargetablesComp;
	// UPlayerMovementComponent MoveComp;
	// UCombatHitStopComponent HitStopComp;
	// USteppingMovementData Movement;

	// float StartVelocity;
	// FVector ForwardVector;
	// FVector AccumulatedTranslation;
	// float TotalMovementLength;
	// float MinimumSuctionDistance;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		
	// 	TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	// 	MoveComp = UPlayerMovementComponent::Get(Owner);
	// 	HitStopComp = UCombatHitStopComponent::Get(Owner);
	// 	Movement = MoveComp.SetupSteppingMovementData();
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!CombatComp.CanStartNewAttack())
	// 		return false;
		
	// 	if(CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Sprint)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::Sprint))
	// 		return true;

	// 	if (ActiveDuration > CombatComp.ActiveAttackData.AnimationData.AttackMetaData.Duration)
	// 		return true;

	// 	if (CombatComp.HasPendingAttack())
	// 	{
	// 		if (CombatComp.bInsideComboWindow)
	// 			return true;
	// 	}

	// 	if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
	// 	CombatComp.StartAttackAnimation();

	// 	if(HasControl())
	// 	{
	// 		StartVelocity = MoveComp.Velocity.Size() * .75;
	// 		AccumulatedTranslation = FVector::ZeroVector;

	// 		// Get forward vector after turning towards movement direction
	// 		//  then use our new forward to find suction target
	// 		// ForwardVector = CombatComp.GetMovementDirection(Player.ViewRotation.ForwardVector);
	// 		ForwardVector = CombatComp.GetMovementDirection(Player.ActorForwardVector);

	// 		TotalMovementLength = CombatComp.ActiveAttackData.AnimationData.AttackMetaData.MovementLength;
	// 		if (CombatComp.ActiveAttackData.Target != nullptr)
	// 		{
	// 			const FVector ToTarget = (CombatComp.ActiveAttackData.Target.WorldLocation - Player.ActorCenterLocation);
	// 			const FVector ToTargetHorizontal = ToTarget.VectorPlaneProject(Player.MovementWorldUp);

	// 			// Calculate minimum distance we want to reach and extend
	// 			//  our total root motion movement length to accommodate
	// 			MinimumSuctionDistance = CombatComp.GetSuctionReachDistance(CombatComp.ActiveAttackData.Target);
	// 			TotalMovementLength = Math::Max(TotalMovementLength, Math::Min(ToTargetHorizontal.Size() - MinimumSuctionDistance, CombatComp.ActiveAttackData.Target.SuctionReachDistance));
	// 		}
	// 	}
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	// Reset current combo when attack finishes
	// 	if(CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
	// 		CombatComp.StopActiveAttackData(this);

	// 	if (IsBlocked())
	// 		CombatComp.UnblockMovement();
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		if(HasControl())
	// 		{
	// 			Movement.StopMovementWhenLeavingEdgeThisFrame();

	// 			FVector RootMovement = SwordComp.GetRootMotion(AccumulatedTranslation, ActiveDuration, TotalMovementLength, CombatComp.ActiveAttackData.AnimationData.AttackMetaData.Duration);

	// 			if (CombatComp.ActiveAttackData.Target != nullptr)
	// 			{
	// 				FVector ToTarget = (CombatComp.ActiveAttackData.Target.WorldLocation - Player.ActorCenterLocation);
	// 				FVector ToTargetHorizontal = ToTarget.VectorPlaneProject(Player.MovementWorldUp);
	// 				FVector ToTargetVertical = (ToTarget - ToTargetHorizontal);

	// 				// Move towards the target horizontally by modifying our forward vector
	// 				float HorizontalStepSize = (ToTargetHorizontal.Size() - MinimumSuctionDistance);

	// 				ForwardVector = ToTargetHorizontal.GetSafeNormal();
	// 				RootMovement = RootMovement.GetClampedToMaxSize(HorizontalStepSize);

	// 				// Remove velocity once we've reached our target
	// 				//  otherwise we'll continue sliding into them
	// 				if (HorizontalStepSize < KINDA_SMALL_NUMBER)
	// 					StartVelocity = 0.0;

	// 				// Apply movement vertically to match our center to the target component location
	// 				bool bIsTargetBelow = (Player.MovementWorldUp.DotProduct(ToTargetVertical.GetSafeNormal()) < 0.0);
	// 				if (bIsTargetBelow)
	// 				{
	// 					float VerticalStepSize = Math::Min(RootMovement.Size(), ToTargetVertical.Size());
	// 					FVector VerticalDirection = (bIsTargetBelow ? -FVector::UpVector : FVector::UpVector);

	// 					RootMovement += (VerticalDirection * VerticalStepSize);
	// 				}
	// 			}
	// 			else
	// 			{
	// 				// Scale root motion movement by input if we don't have a target
	// 				//  otherwise we always want to move at full speed
	// 				RootMovement *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0),
	// 					DragonSwordCombat::RootMovementInputScale,
	// 					MoveComp.MovementInput.Size());
	// 			}

	// 			FQuat TargetRotation = FQuat::MakeFromZX(Player.MovementWorldUp, ForwardVector);
	// 			FQuat NewRotation = FQuat::Slerp(Player.ActorQuat, TargetRotation, 12.0 * DeltaTime);
	// 			FVector DeltaMovement = TargetRotation.RotateVector(RootMovement);

	// 			if (StartVelocity > KINDA_SMALL_NUMBER)
	// 			{
	// 				StartVelocity -= (StartVelocity * 3.0 * DeltaTime);
	// 				Movement.AddVelocity(ForwardVector * StartVelocity);
	// 			}

	// 			DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);

	// 			Movement.AddDelta(DeltaMovement);
	// 			Movement.SetRotation(NewRotation);
	// 			Movement.AddGravityAcceleration();
	// 		}
	// 		else
	// 		{
	// 			Movement.ApplyCrumbSyncedGroundMovement();
	// 		}

	// 		MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
	// 	}

	// 	if(HasControl())
	// 	{
	// 		if (CombatComp.bInsideHitWindow)
	// 			CombatComp.TryAttack();
	// 	}
	// }
}