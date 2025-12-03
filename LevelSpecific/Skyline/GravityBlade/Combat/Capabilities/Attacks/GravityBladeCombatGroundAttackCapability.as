class UGravityBladeCombatGroundAttackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAttack);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeGroundAttack);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UCombatHitStopComponent HitStopComp;
	USteppingMovementData Movement;

	float StartVelocity;
	FVector ForwardVector;

	float MovementLengthBeforeHit;
	float MovementLengthAfterHit;

	float TargetSuctionDistance;
	float MinimumSuctionDistance;
	float AnimationDuration;
	bool bRotateToFollowInput = true;
	float CurrentStartTime;
	float CurrentPlayRate;
	float TimeToHit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!CombatComp.HasPendingAttack())
			return false;

		if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::Ground)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::Ground)
			return true;

		if (ActiveDuration > AnimationDuration)
			return true;

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		CombatComp.StartAttackAnimation();
		BladeComp.UnsheatheBlade();

		AnimationDuration = (CombatComp.ActiveAttackData.AnimationData.AttackMetaData.Duration - CombatComp.CurrentSpeedUpStartTime) / CombatComp.CurrentSpeedUpPlayRate;
		CurrentStartTime = CombatComp.CurrentSpeedUpStartTime;
		CurrentPlayRate = CombatComp.CurrentSpeedUpPlayRate;
		bRotateToFollowInput = true;

		if(HasControl())
		{
			StartVelocity = MoveComp.Velocity.Size() * .75;

			// Get forward vector after turning towards movement direction
			//  then use our new forward to find suction target
			ForwardVector = CombatComp.GetMovementDirection(Player.ViewRotation.ForwardVector);
			TimeToHit = CombatComp.GetTimeToHit(CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData);

			if (CombatComp.ActiveAttackData.Target != nullptr)
			{
				const FVector ToTarget = (CombatComp.ActiveAttackData.Target.WorldLocation - Player.ActorCenterLocation);
				const FVector ToTargetHorizontal = ToTarget.VectorPlaneProject(Player.MovementWorldUp);

				// Calculate minimum distance we want to reach and extend
				//  our total root motion movement length to accommodate
				TargetSuctionDistance = CombatComp.GetSuctionReachDistance(CombatComp.ActiveAttackData.Target);
				MinimumSuctionDistance = CombatComp.GetSuctionMinimumDistance(CombatComp.ActiveAttackData.Target);

				float CurrentDistance = ToTargetHorizontal.Size();
				if (CurrentDistance < MinimumSuctionDistance)
					MovementLengthBeforeHit = (CurrentDistance - MinimumSuctionDistance);
				else if (CurrentDistance > TargetSuctionDistance)
					MovementLengthBeforeHit = (CurrentDistance - TargetSuctionDistance);
				else
					MovementLengthBeforeHit = 0.0;

				MovementLengthAfterHit = CombatComp.GetMovementLengthAfterHit(CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData);
			}
			else
			{
				MovementLengthBeforeHit = CombatComp.GetMovementLengthBeforeHit(CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData);
				MovementLengthAfterHit = CombatComp.GetMovementLengthAfterHit(CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData);
			}
		}

		if (CombatComp.ActiveAttackData.Target != nullptr)
		{
			auto InteractionResponseComp = UGravityBladeCombatInteractionResponseComponent::Get(CombatComp.ActiveAttackData.Target.Owner);
			if (InteractionResponseComp != nullptr)
			{
				if (InteractionResponseComp.bSmoothTeleportOnHit)
				{
					MovementLengthBeforeHit = 0;
					MovementLengthAfterHit = 0;
					InteractionResponseComp.TriggerSmoothTeleport(Player);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Target", CombatComp.ActiveAttackData.IsValid() ? CombatComp.ActiveAttackData.Target : nullptr);
		TemporalLog.Value("TotalMovementLength", MovementLengthBeforeHit);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Reset current combo when attack finishes
		CombatComp.StopActiveAttackData(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector RootMovement;

				if (CombatComp.ActiveAttackData.Target != nullptr)
				{
					if (ActiveDuration > TimeToHit)
						RootMovement = BladeComp.GetRootMotionAfterHit(ActiveDuration, DeltaTime, MovementLengthAfterHit, AnimationDuration);
					else
						RootMovement = BladeComp.GetLinearMotionBeforeHit(ActiveDuration, DeltaTime, MovementLengthBeforeHit, AnimationDuration);

					FVector ToTarget = (CombatComp.ActiveAttackData.Target.WorldLocation - Player.ActorCenterLocation);
					FVector ToTargetHorizontal = ToTarget.VectorPlaneProject(Player.MovementWorldUp);
					FVector ToTargetVertical = (ToTarget - ToTargetHorizontal);

					// Move towards the target horizontally by modifying our forward vector
					float HorizontalStepSize = (ToTargetHorizontal.Size() - TargetSuctionDistance);

					ForwardVector = ToTargetHorizontal.GetSafeNormal();
					RootMovement = RootMovement.GetClampedToMaxSize(Math::Abs(HorizontalStepSize));

					// Remove velocity once we've reached our target
					//  otherwise we'll continue sliding into them
					if (HorizontalStepSize < KINDA_SMALL_NUMBER)
						StartVelocity = 0.0;

					// Apply movement vertically to match our center to the target component location
					bool bIsTargetBelow = (Player.MovementWorldUp.DotProduct(ToTargetVertical.GetSafeNormal()) < 0.0);
					if (bIsTargetBelow)
					{
						float VerticalStepSize = Math::Min(RootMovement.Size(), ToTargetVertical.Size());
						FVector VerticalDirection = (bIsTargetBelow ? -FVector::UpVector : FVector::UpVector);

						RootMovement += (VerticalDirection * VerticalStepSize);
					}
				}
				else
				{
					RootMovement = BladeComp.GetRootMotionForFullAnimation(
						ActiveDuration, DeltaTime,
						MovementLengthBeforeHit + MovementLengthAfterHit,
						AnimationDuration);

					if(CombatComp.bInsideHitWindow)
						bRotateToFollowInput = false;

					if(bRotateToFollowInput && !MoveComp.MovementInput.IsNearlyZero())
						ForwardVector = MoveComp.MovementInput.GetSafeNormal();

					// Scale root motion movement by input if we don't have a target
					//  otherwise we always want to move at full speed
					// RootMovement *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0),
					// 	GravityBladeCombat::RootMovementInputScale,
					// 	MoveComp.MovementInput.Size());
				}

				FQuat TargetRotation = FQuat::MakeFromZX(Player.MovementWorldUp, ForwardVector);
				FQuat NewRotation;
				
				float RotationAlpha = 12.0 * DeltaTime;
				if(CombatComp.ActiveAttackData.Target == nullptr)
				{
					auto AnimationSequence = CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData.Animation.Sequence;
					float CurrentTime = ActiveDuration * CurrentPlayRate + CurrentStartTime;
					float TargetDuration = AnimationSequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow);
	
					RotationAlpha = CurrentTime / TargetDuration;
					RotationAlpha = Math::Clamp(RotationAlpha, 0.0, 1.0);
				}

				bool bRotateInDirection = Player.ActorForwardVector.GetAngleDegreesTo(TargetRotation.ForwardVector) > GravityBladeCombat::PickRotationDirectionDegreeThreshold;

				float Degrees = Math::GetAngleDegreesInDirection(Player.ActorRotation.Yaw, TargetRotation.Rotator().Yaw, CombatComp.AnimData.bFirstFrameHasRightFootForward);
				if(!bRotateInDirection)
					Degrees = Math::UnwindDegrees(Degrees);

				CombatComp.AnimData.AngleLeftToRotate = Degrees;
				
				if(bRotateInDirection)
				{
					float NewYaw = Math::LerpAngleDegreesInDirection(Player.ActorRotation.Yaw, TargetRotation.Rotator().Yaw, RotationAlpha, CombatComp.AnimData.bFirstFrameHasRightFootForward);
					NewRotation = FRotator(Player.ActorRotation.Pitch, NewYaw, Player.ActorRotation.Roll).Quaternion();
				}
				else
					NewRotation = FQuat::Slerp(Player.ActorQuat, TargetRotation, RotationAlpha);

				FVector DeltaMovement;
				if(CombatComp.ActiveAttackData.Target != nullptr)
					DeltaMovement = TargetRotation.RotateVector(RootMovement);
				else
					DeltaMovement = NewRotation.RotateVector(RootMovement);

				if (StartVelocity > KINDA_SMALL_NUMBER)
				{
					StartVelocity -= (StartVelocity * 3.0 * DeltaTime);
					Movement.AddVelocity(ForwardVector * StartVelocity);
				}

				DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);

				// 	// Make sure that we don't move too close, or past, the enemy
				// 	FVector TargetLocationOnGroundPlane = CombatComp.ActiveAttackData.Target.WorldLocation.PointPlaneProject(Player.ActorLocation, Player.MovementWorldUp);
				// 	FVector ToPlayerFromTarget = Player.ActorLocation - TargetLocationOnGroundPlane;

				// 	FVector PlayerLocationAfterMove = Player.ActorLocation + DeltaMovement;
				// 	FPlane TargetPlane = FPlane(TargetLocationOnGroundPlane, (Player.ActorLocation - TargetLocationOnGroundPlane).GetSafeNormal());
				// 	if(TargetPlane.PlaneDot(PlayerLocationAfterMove) < 0)
				// 	{
				// 		// The location after the move will be behind the target! Move to in front.
				// 		DeltaMovement = (TargetLocationOnGroundPlane + ToPlayerFromTarget.GetSafeNormal() * GravityBladeCombat::IdealTargetDistance) - Player.ActorLocation;
				// 	}
				// 	else
				// 	{
				// 		if(PlayerLocationAfterMove.DistSquared(TargetLocationOnGroundPlane) < Math::Square(GravityBladeCombat::IdealTargetDistance))
				// 		{
				// 			// We are too close, move back
				// 			FVector ToPlayerAfterMoveFromTarget = PlayerLocationAfterMove - TargetLocationOnGroundPlane;
				// 			PlayerLocationAfterMove -= ToPlayerAfterMoveFromTarget.GetSafeNormal() * GravityBladeCombat::IdealTargetDistance;
				// 			DeltaMovement = PlayerLocationAfterMove - Player.ActorLocation;
				// 		}
				// 	}

				Movement.AddDeltaWithCustomVelocity(DeltaMovement, FVector::ZeroVector, EMovementDeltaType::Horizontal);
				Movement.AddOwnerVerticalVelocity();

				// Only stop when moving over edges if we don't move too fast.
				if(DeltaMovement.Size() < 100)
				{
					// Using this requires EdgeHandling to be turned on in the resolver,
					// which requires substepping, which is limited in the distance
					// we can travel to prevent excessive iterations.
					Movement.StopMovementWhenLeavingEdgeThisFrame();
				}

				if(bRotateToFollowInput)
					Movement.SetRotation(NewRotation);
				
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, GravityBladeCombat::Feature);
		}

		if(HasControl())
		{
#if EDITOR
			CombatComp.DebugDrawAttack(ForwardVector, TargetSuctionDistance);
#endif
		}

	}
}