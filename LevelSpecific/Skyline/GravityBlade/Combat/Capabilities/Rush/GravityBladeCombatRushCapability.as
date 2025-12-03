class UGravityBladeCombatRushCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeRush);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	float TimeForAnimationToHit;
	float TimeToReachTarget;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FRotator StartRotation;
	FVector StartLocation;
	bool bAttack = false;
	float AttackStartTime = 0;

	FVector TargetLocation;
	FRotator TargetRotation;
	bool bWithinRotationThreshold = false;
	float RushSpeed;
	float AnimationDuration;
	bool bCameraSettingsActive = false;
	bool bHasHit;
	bool bIsAirRush;

	float TimeToRotate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
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

		if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::GroundRush
			&& CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::AirRush)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::GroundRush
			&& CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::AirRush)
			return true;

		if(bAttack)
		{
			float TimeSinceAttackStart = Time::GetGameTimeSince(AttackStartTime);
			if (TimeSinceAttackStart > AnimationDuration)
				return true;
		}

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if (MoveComp.HasWallContact())
			return true;

		if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;

		// If we have rushed for 50% more time than it should have taken then something is probably wrong so exit.
		if(!bAttack && ActualActiveDuration > TimeToReachTarget * 1.5)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeComp.UnsheatheBlade();
		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		Player.ApplyCameraSettings(CombatComp.CameraSettingsInRush, CombatComp.CameraSettingsInRushBlendInTime, this, EHazeCameraPriority::High);
		bCameraSettingsActive = true;
		bHasHit = false;
		bIsAirRush = CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::AirRush;

		AnimationDuration = (CombatComp.ActiveAttackData.AnimationData.AttackMetaData.Duration - CombatComp.CurrentSpeedUpStartTime) / CombatComp.CurrentSpeedUpPlayRate;

		if(HasControl())
		{
			bAttack = false;
			Player.BlockCapabilities(GravityBladeTags::GravityBladeAttackTrace, this);
		}

		StartLocation = Player.ActorLocation;
		StartRotation = Player.ActorRotation;

		auto AnimationSequence = CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData.Animation.Sequence;
		TimeForAnimationToHit = AnimationSequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow);

		GravityBladeCombatRush::CalculateTargetLocationAndRotation(
			bIsAirRush,
			Player,
			CombatComp.ActiveAttackData.Target,
			StartLocation,
			TargetLocation,
			TargetRotation
		);
		
		RushSpeed = GravityBladeCombat::RushSpeed * CombatComp.CurrentSpeedUpRushSpeedMultiplier;

		TimeToReachTarget = StartLocation.Distance(TargetLocation) / RushSpeed;
		if (TimeToReachTarget > GravityBladeCombat::RushMaxTimeToReachTarget)
		{
			RushSpeed *= (TimeToReachTarget / GravityBladeCombat::RushMaxTimeToReachTarget);
			TimeToReachTarget = GravityBladeCombat::RushMaxTimeToReachTarget;
		}
		else if (TimeToReachTarget < GravityBladeCombat::RushMinTimeToReachTarget)
		{
			RushSpeed *= (TimeToReachTarget / GravityBladeCombat::RushMinTimeToReachTarget);
			TimeToReachTarget = GravityBladeCombat::RushMinTimeToReachTarget;
		}
		
		FGravityBladeCombatStartRushEventData EventData;
		EventData.StartLocation = StartLocation;
		EventData.EndLocation = TargetLocation;
		EventData.TimeForAnimationToHit = TimeForAnimationToHit;
		UGravityBladeCombatEventHandler::Trigger_StartRush(BladeComp.Blade, EventData);

		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);

		float Degrees = TargetRotation.ForwardVector.GetAngleDegreesTo(Player.ActorForwardVector);
		bWithinRotationThreshold = Degrees < GravityBladeCombat::PickRotationDirectionDegreeThreshold;
		if (!bWithinRotationThreshold)
			Degrees = Math::GetAngleDegreesInDirection(Player.ActorRotation.Yaw, TargetRotation.Yaw, CombatComp.AnimData.bFirstFrameHasRightFootForward);
		TimeToRotate = Math::Abs(Degrees) / GravityBladeCombat::RushCharacterRotationSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CombatComp.StopActiveAttackData(this);

		if(bCameraSettingsActive)
		{
			Player.ClearCameraSettingsByInstigator(this, CombatComp.CameraSettingsInRushBlendOutTime);
			bCameraSettingsActive = false;
		}
		
		if(BladeComp.Blade != nullptr)
			UGravityBladeCombatEventHandler::Trigger_StopRush(BladeComp.Blade);

		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);

		if (!bAttack && HasControl())
			Player.UnblockCapabilities(GravityBladeTags::GravityBladeAttackTrace, this);

		if(CombatComp.ThrowBladeData.Instigator == this)
			CombatComp.CrumbClearThrowBladeTargetByInstigator(this);

		// Clamp our exit velocity so we don't end up going super fast if the move is cancelled by velocity
		Player.SetActorHorizontalVelocity(Player.ActorHorizontalVelocity.GetClampedToMaxSize(800.0));
		Player.SetActorVerticalVelocity(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GravityBladeCombatRush::CalculateTargetLocationAndRotation(
			bIsAirRush,
			Player,
			CombatComp.ActiveAttackData.Target,
			StartLocation,
			TargetLocation,
			TargetRotation
		);

		float Degrees = Math::GetAngleDegreesInDirection(Player.ActorRotation.Yaw, TargetRotation.Yaw, CombatComp.AnimData.bFirstFrameHasRightFootForward);
		if (bWithinRotationThreshold)
			Degrees = Math::UnwindDegrees(Degrees);

		// We only rotate before the combo window, so if we enter the combo window the angle should be 0
		if(!CombatComp.bInsideComboWindow)
			CombatComp.AnimData.AngleLeftToRotate = Degrees;
		else
			CombatComp.AnimData.AngleLeftToRotate = 0.0;
			
		if(HasControl() && CombatComp.bInsideThrowBladeWindow && CombatComp.ThrowBladeData.Instigator != this)
			CombatComp.CrumbTrySetThrowBladeTarget(CombatComp.ActiveAttackData.Target, GravityBladeGrapple::ThrowSpeed, Math::Abs(Math::Min(0.0, ActualActiveDuration)), this);
		else if(HasControl() && !CombatComp.bInsideThrowBladeWindow && CombatComp.ThrowBladeData.Instigator == this)
			CombatComp.CrumbClearThrowBladeTargetByInstigator(this);

		float Alpha = Math::Saturate(ActualActiveDuration / TimeToReachTarget);
		float RemainingTimeToTarget = TimeToReachTarget - ActualActiveDuration;
		CombatComp.AnimData.RushAlpha = Alpha;

		if (CombatComp.bInsideHitWindow)
			bHasHit = true;

		float RotationAlpha = Math::Saturate(ActualActiveDuration / TimeToRotate);

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TotalDistance = TargetLocation - StartLocation;
				FVector HorizontalDistance = TotalDistance.ConstrainToPlane(MoveComp.WorldUp);
				FVector VerticalDistance = TotalDistance.ConstrainToDirection(MoveComp.WorldUp);

				float HorizontalAlpha = Alpha;
				float VerticalAlpha = Math::Saturate(ActualActiveDuration / Math::Min(TimeToReachTarget, GravityBladeCombat::RushVerticalAdjustTime));

				FVector NewLocation = StartLocation + HorizontalDistance * HorizontalAlpha + VerticalDistance * VerticalAlpha;

				// Don't follow the enemy after we do our first hit
				if (bHasHit)
					NewLocation = Player.ActorLocation;

				FRotator NewRotation;

				if(!bWithinRotationThreshold)
				{
					float NewYaw = Math::LerpAngleDegreesInDirection(
						StartRotation.Yaw, TargetRotation.Yaw,
						RotationAlpha, CombatComp.AnimData.bFirstFrameHasRightFootForward);
					NewRotation = FRotator(Player.ActorRotation.Pitch, NewYaw, Player.ActorRotation.Roll);
				}
				else
				{
					NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, RotationAlpha);
				}

				const FVector Delta = NewLocation - Player.ActorLocation;

				// We still want to lock movement so we still prepare and apply move but just don't do anything in the move when the rush is done.
				if(!CombatComp.bInsideComboWindow)
				{
					// We only want to move when anticipation delay has passed.
					if(ActualActiveDuration >= 0.0)
						Movement.AddDelta(Delta);
					Movement.SetRotation(NewRotation);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, GravityBladeCombat::Feature);
		}

		float FFFrequency = 50.0;
		float FFIntensity = 0.3;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);

		if(HasControl())
		{
			if((TimeForAnimationToHit < 0.01 || RemainingTimeToTarget < TimeForAnimationToHit) && !bAttack && ActualActiveDuration > 0.0)
			{
				bAttack = true;
				AttackStartTime = Time::GameTimeSeconds;

				if (HasControl())
					Player.UnblockCapabilities(GravityBladeTags::GravityBladeAttackTrace, this);

				CombatComp.CrumbStartAttackAnimation();

				if(bCameraSettingsActive)
				{
					Player.ClearCameraSettingsByInstigator(this, CombatComp.CameraSettingsInRushBlendOutTime);
					bCameraSettingsActive = false;
				}
			}
#if EDITOR
			//GravityBladeCombatRush::DebugDraw(StartLocation, TargetLocation, AdjustedRushSpeed(), TimeForAnimationToHit);
#endif
		}

	}

	// Will return the active duration - the anticipation delay so it will be the actual time the rush/attack has been going on for.
	private float GetActualActiveDuration() const property
	{
		return ActiveDuration - AnticipationDelay;
	}

	private float GetAnticipationDelay() const property
	{
		if (bIsAirRush)
			return CombatComp.AnimFeature.AnimData.AirRushAnticipationDelay;
		else
			return CombatComp.AnimFeature.AnimData.GroundRushAnticipationDelay;
	}
}