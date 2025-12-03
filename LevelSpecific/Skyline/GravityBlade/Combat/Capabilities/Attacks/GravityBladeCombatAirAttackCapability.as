class UGravityBladeCombatAirAttackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAttack);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAirAttack);

	default InterruptsCapabilities(GravityBladeCombatTags::GravityBladeGroundAttack);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	UPlayerSwimmingComponent SwimmingComp;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UCombatHitStopComponent HitStopComp;
	USweepingMovementData Movement;

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
		SwimmingComp = UPlayerSwimmingComponent::Get(Owner);
		
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
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

		if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::Air
			&& CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::AirSlam
			&& CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::AirHover
		)
		{
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::Air
			&& CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::AirSlam
			&& CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::AirHover
		)
		{
			return true;
		}

		if (ActiveDuration > AnimationDuration)
			return true;

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;


		if (CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::AirSlam)
		{
			if (MoveComp.HasGroundContact())
				return true;
		}

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
			StartVelocity = MoveComp.HorizontalVelocity.Size() * .75;

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
					FVector ToTargetHorizontal = ToTarget.ConstrainToPlane(Player.MovementWorldUp);
					FVector ToTargetVertical = (ToTarget - ToTargetHorizontal);

					// Move towards the target horizontally by modifying our forward vector
					float HorizontalStepSize = (ToTargetHorizontal.Size() - TargetSuctionDistance);

					ForwardVector = ToTargetHorizontal.GetSafeNormal();
					RootMovement = RootMovement.GetSafeNormal() * Math::Min(RootMovement.Size(), Math::Abs(HorizontalStepSize));

					// Remove velocity once we've reached our target
					//  otherwise we'll continue sliding into them
					if (HorizontalStepSize < KINDA_SMALL_NUMBER)
						StartVelocity = 0.0;

					// If the enemy is below us we fall down to them naturally using gravity
					bool bIsMovingUp = MoveComp.Velocity.DotProduct(MoveComp.WorldUp) > 0;
					if (CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::Air || bIsMovingUp)
					{
						bool bIsTargetBelow = (Player.MovementWorldUp.DotProduct(ToTargetVertical.GetSafeNormal()) < 0.0);
						if (bIsTargetBelow)
						{
							Movement.AddGravityAcceleration();
							Movement.AddOwnerVerticalVelocity();
						}
					}
				}
				else
				{
					RootMovement = BladeComp.GetRootMotionForFullAnimation(
						ActiveDuration, DeltaTime,
						MovementLengthBeforeHit + MovementLengthAfterHit,
						AnimationDuration);

					bool bIsMovingUp = MoveComp.Velocity.DotProduct(MoveComp.WorldUp) > 0;
					if(SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active
						&& (CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::Air || bIsMovingUp || !CombatComp.AllowAirAttackHover.Get()))
					{
						Movement.AddGravityAcceleration();
						Movement.AddOwnerVerticalVelocity();
					}

					if(CombatComp.bInsideHitWindow)
						bRotateToFollowInput = false;

					if(bRotateToFollowInput && !MoveComp.MovementInput.IsNearlyZero())
						ForwardVector = MoveComp.MovementInput.GetSafeNormal();

					ForwardVector = ForwardVector.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
					if (ForwardVector.IsNearlyZero())
						ForwardVector = Player.ActorForwardVector;

					// Scale root motion movement by input if we don't have a target
					//  otherwise we always want to move at full speed
					RootMovement *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0),
						GravityBladeCombat::RootMovementInputScale,
						MoveComp.MovementInput.Size());
				}

				if (CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::AirSlam
					&& ActiveDuration > GravityBladeCombat::AirSlamAnticipationDuration)
				{
					Movement.AddVelocity(MoveComp.WorldUp * -GravityBladeCombat::AirSlamDownwardSpeed);
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
					if (CombatComp.ActiveAttackData.Target != nullptr)
						StartVelocity *= Math::Pow(0.01, DeltaTime);
					Movement.AddVelocity(ForwardVector * StartVelocity);
				}

				DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);
				Movement.AddDelta(DeltaMovement);
				
				if(bRotateToFollowInput)
					Movement.SetRotation(NewRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
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