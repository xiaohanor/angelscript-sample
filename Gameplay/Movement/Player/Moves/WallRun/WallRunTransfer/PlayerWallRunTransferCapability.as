
class UPlayerWallRunTransferCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunJump);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 33;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 1);

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallRunComponent WallRunComp;
	UPlayerAirMotionComponent AirMotionComp;

	FPlayerWallRunData PreviousWallData;
	FPlayerWallRunTransferParams TransferParams;

	FDashMovementCalculator SidewaysCalculator;
	FDashMovementCalculator ExtraForwardCalculator;
	// bool bAirJumpBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Owner);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(WallRunComp.IsGraceTransferAllowed())
		{
			if(!MoveComp.IsInAir())
			{
				WallRunComp.ClearTransferGrace();
			}
			else if (Time::GetGameTimeSince(WallRunComp.GetGraceWindowInitiatedAt()) >= WallRunComp.Settings.TransferGraceWindow)
				WallRunComp.ClearTransferGrace();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallRunTransferParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if ((WallRunComp.State != EPlayerWallRunState::WallRun && WallRunComp.State != EPlayerWallRunState::WallRunLedge) && !WallRunComp.IsGraceTransferAllowed())
        	return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceJump)
			return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceForwardJump)
			return false;

		if (WallRunComp.Settings.JumpOverride == EPlayerWallRunJumpOverride::ForceTransfer)
			return true;

		if (Time::GetGameTimeSince(WallRunComp.LastWallRunStartTime) < WallRunComp.Settings.WallRunJumpOffInitialCooldown)
			return false;

		if (!TraceForTransfer(ActivationParams))
			return false;

		return true;
	}

	bool TraceForTransfer(FPlayerWallRunTransferParams& OutParams) const
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(this.ToString());
#endif
		FVector WallNormal = WallRunComp.ActiveData.HasValidData() ? WallRunComp.ActiveData.WallNormal : WallRunComp.StoredGraceWallRotation.ForwardVector;

		// Trace sideways with the maximum transfer distance, and forward
		// with how much our velocity would go forward during the transfer duration
		float MaxDuration = WallRunComp.TransferSettings.MaxTransferDistance / WallRunComp.TransferSettings.TransferSpeed;
		FVector TraceDelta = MoveComp.HorizontalVelocity * MaxDuration;
		TraceDelta += WallNormal * WallRunComp.TransferSettings.MaxTransferDistance;
		TraceDelta += MoveComp.HorizontalVelocity.GetSafeNormal() * WallRunComp.TransferSettings.ExtraForwardSpeedDuringTransfer;

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart + TraceDelta;

		if (IsDebugActive())
			TraceSettings.DebugDraw(5.0);

		/** Trace for the wall opposite to us first */
		FHitResult OppositeHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
		TemporalLog.HitResults("OppositeHit", OppositeHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if (!OppositeHit.bBlockingHit)
			return false;

		if (!OppositeHit.Component.HasTag(ComponentTags::WallRunnable))
			return false;

		const float WallPitch = 90.0 - Math::RadiansToDegrees(OppositeHit.Normal.AngularDistance(Player.MovementWorldUp));
		if (WallPitch > WallRunComp.WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallRunComp.WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return false;

		const FVector FlattenedWallNormal = WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		const FVector FlattenedTraceNormal = OppositeHit.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		if (Math::RadiansToDegrees(FlattenedWallNormal.AngularDistance(FlattenedTraceNormal)) < 160.0)
			return false;

		/* Head & Foot trace
			Test to see if the head and feet land on something valid
			Take the hit location and trace towards to find head and foot location towards the normal
			Could probably move this into a "TraceForPlanting" function
		*/
		FHazeTraceSettings HeadFootTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		HeadFootTraceSettings.UseLine();

		if (IsDebugActive())
			HeadFootTraceSettings.DebugDraw(5.0);
		
		FVector HeadTraceStart = OppositeHit.Location + (Player.MovementWorldUp * 100.0);
		FVector HeadTraceEnd = HeadTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		FHitResult HeadHit = HeadFootTraceSettings.QueryTraceSingle(HeadTraceStart, HeadTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("HeadHit", HeadHit, HeadFootTraceSettings.Shape, HeadFootTraceSettings.ShapeWorldOffset);
#endif

		if (!HeadHit.bBlockingHit)
			return false;
		
		FVector FootTraceStart = OppositeHit.Location + (Player.MovementWorldUp * 25.0);
		FVector FootTraceEnd = FootTraceStart - FlattenedTraceNormal * Player.CapsuleComponent.CapsuleRadius * 2.0;

		FHitResult FootHit = HeadFootTraceSettings.QueryTraceSingle(FootTraceStart, FootTraceEnd);

#if !RELEASE
		TemporalLog.HitResults("FootHit", HeadHit, HeadFootTraceSettings.Shape, HeadFootTraceSettings.ShapeWorldOffset);
#endif

		if (!FootHit.bBlockingHit)
			return false;

		/** All our traces are valid, calculate what kind of arc we should be making for the transfer. */
		FVector TargetLocation = OppositeHit.Location;

		// If we are already wallrunning above where we want to limit our height, make the transfer take some extra height away
		float LostHeight = WallRunComp.TransferSettings.TransferLostHeight;
		if (WallRunComp.bHasWallRunnedSinceLastGrounded)
		{
			float CurHeight = Player.ActorLocation.DotProduct(MoveComp.WorldUp);
			float HeightLimit = WallRunComp.InitialWallRunHeightLimitLocation.DotProduct(MoveComp.WorldUp);

			LostHeight += Math::Min(CurHeight - HeightLimit, 100.0);
		}	

		//Using Player forward here feels wrong as we are turning mid air (even if the window for transfer is short enough this shouldnt matter)
		//But i would still rather we lock in our travel direction
		OutParams.ForwardDirection = WallNormal.CrossProduct(MoveComp.WorldUp) * Math::Sign((WallNormal.CrossProduct(MoveComp.WorldUp).DotProduct(Player.ActorForwardVector)));
		OutParams.SidewaysDirection = WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		OutParams.SidewaysDistance = (TargetLocation - Player.ActorLocation).DotProduct(OutParams.SidewaysDirection);
		OutParams.TransferDuration = Math::Max(OutParams.SidewaysDistance / WallRunComp.TransferSettings.TransferSpeed, 0.2);
		OutParams.VerticalImpulse = Trajectory::GetSpeedToReachTarget(-LostHeight, OutParams.TransferDuration, -MoveComp.GetGravityForce());
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerWallRunData& DeactivationWallRunData) const
	{	
		if (MoveComp.HasMovedThisFrame())
        	return true;

		if (MoveComp.IsOnWalkableGround())
        	return true;
		
		FVector TraceDirection;
		if(!MoveComp.HorizontalVelocity.IsNearlyZero())
			TraceDirection = MoveComp.HorizontalVelocity.GetSafeNormal();
		else if (!MoveComp.PreviousHorizontalVelocity.IsNearlyZero())
			TraceDirection = MoveComp.PreviousHorizontalVelocity.GetSafeNormal();
		else
			TraceDirection = !MoveComp.MovementInput.IsNearlyZero() ? MoveComp.MovementInput.GetSafeNormal() : Player.ActorForwardVector;
		FPlayerWallRunData WallRunData = WallRunComp.TraceForWallRun(Player, TraceDirection, FInstigator(this, n"ShouldDeactivate"));
		if (WallRunData.HasValidData())
		{
			FVector WallNormalToUse = PreviousWallData.HasValidData() ? PreviousWallData.WallNormal : WallRunComp.StoredGraceWallRotation.ForwardVector;

			float AngularDistance = Math::RadiansToDegrees(WallNormalToUse.AngularDistance(WallRunData.WallNormal));
			if (Math::IsNearlyEqual(AngularDistance, 180.0, WallRunComp.TransferSettings.WallRunEnterAcceptanceAngle))
			{
				DeactivationWallRunData = WallRunData;
				return true;
			}
		}

		if (ActiveDuration >= TransferParams.TransferDuration)
        	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallRunTransferParams ActivationParams)
	{
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);

		PreviousWallData = WallRunComp.ActiveData;
		TransferParams = ActivationParams;

		WallRunComp.SetState(EPlayerWallRunState::Transfer);
		WallRunComp.ActiveData.Reset();

		Player.SetActorVelocity(Player.ActorHorizontalVelocity + MoveComp.WorldUp * TransferParams.VerticalImpulse);

		SidewaysCalculator = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			TransferParams.SidewaysDistance, TransferParams.TransferDuration,
			WallRunComp.TransferSettings.TransferAccelerationDuration,
			WallRunComp.TransferSettings.TransferDecelerationDuration,
			0.0, 0.0
		);

		ExtraForwardCalculator = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			WallRunComp.TransferSettings.ExtraForwardSpeedDuringTransfer * TransferParams.TransferDuration,
			TransferParams.TransferDuration,
			WallRunComp.TransferSettings.TransferAccelerationDuration,
			WallRunComp.TransferSettings.TransferDecelerationDuration,
			0.0, 0.0
		);

		if(!WallRunComp.ActiveData.HasValidData())
		{
			FVector Velocity = Player.ActorVelocity;		
			const float RunDirection = Math::Sign(WallRunComp.StoredGraceWallRotation.RightVector.DotProduct(Velocity));
			WallRunComp.AnimData.RunAngle = Math::RadiansToDegrees(WallRunComp.StoredGraceWallRotation.UpVector.AngularDistance(Velocity.GetSafeNormal()));

			if (!Math::IsNearlyEqual(Math::Abs(WallRunComp.AnimData.RunAngle), 180.0))
					WallRunComp.AnimData.RunAngle *= RunDirection;
		}

		// if (WallRunComp.TransferSettings.BlockAirJumpWindowTime > 0.0)
		// {
		// 	Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		// 	bAirJumpBlocked = true;
		// }

		if(WallRunComp.FF_WallrunJumpOut != nullptr)
			Player.PlayForceFeedback(WallRunComp.FF_WallrunJumpOut, this);

		UPlayerCoreMovementEffectHandler::Trigger_Wallrun_Transfer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerWallRunData DeactivationWallRunData)
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);

		WallRunComp.StateCompleted(EPlayerWallRunState::Transfer);

		if (DeactivationWallRunData.HasValidData())			
		{
			WallRunComp.StartWallRun(DeactivationWallRunData);
		}
		else
		{
			// The transfer jump was cancelled by something (air jump or the like),
			// clamp horizontal velocity so we can't use this to boost.
			FVector HorizVelocity = Player.ActorHorizontalVelocity;
			Player.SetActorHorizontalVelocity(HorizVelocity.GetClampedToMaxSize(
				AirMotionComp.Settings.MaximumHorizontalMoveSpeedBeforeDrag
			));
		}

		// If we cancelled with the air jump still blocked, unblock
		// if (bAirJumpBlocked)
		// {
		// 	Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		// 	bAirJumpBlocked = false;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FTemporalLog TempLog = TEMPORAL_LOG(this);

				// Forward velocity is maintained
				FVector ForwardVelocity = MoveComp.HorizontalVelocity.ConstrainToDirection(TransferParams.ForwardDirection);
				Movement.AddHorizontalVelocity(ForwardVelocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				// Sideways velocity uses a dash calculator 
				float SidewaysMovement;
				float SidewaysSpeed;

				SidewaysCalculator.CalculateMovement(
					ActiveDuration, DeltaTime,
					SidewaysMovement, SidewaysSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					TransferParams.SidewaysDirection * SidewaysMovement,
					TransferParams.SidewaysDirection * SidewaysSpeed,
					EMovementDeltaType::Native
				);

				// We add some extra forward speed so this seems more like a 'dash' than a 'sideways jump'
				float ExtraForwardMovement;
				float ExtraForwardSpeed;

				ExtraForwardCalculator.CalculateMovement(
					ActiveDuration, DeltaTime,
					ExtraForwardMovement, ExtraForwardSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					TransferParams.ForwardDirection * ExtraForwardMovement,
					FVector::ZeroVector,
					EMovementDeltaType::Native
				);

				FVector TargetFacingDirection = MoveComp.MovementInput.GetSafeNormal();
				if (TargetFacingDirection.IsNearlyZero())
					TargetFacingDirection = Owner.ActorForwardVector;

				FRotator TargetRotation = FRotator::MakeFromXZ(TargetFacingDirection, MoveComp.WorldUp);
				TargetRotation.Pitch = 0.0;

				const float FacingDirectionScale = Math::Clamp((ActiveDuration - WallRunComp.TransferSettings.NoRotationTime) / WallRunComp.TransferSettings.RotationLerpTime, SMALL_NUMBER, 1.0);
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 360.0 * FacingDirectionScale));

				TempLog.Value("Extra Forward",  ExtraForwardMovement);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallRun");
		}
		
		// // Unblock air jump after our initial window runs out
		// if (bAirJumpBlocked && WallRunComp.TransferSettings.BlockAirJumpWindowTime < ActiveDuration)
		// {
		// 	Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		// 	bAirJumpBlocked = false;
		// }
	}
}

struct FPlayerWallRunTransferParams
{
	FVector ForwardDirection;
	FVector SidewaysDirection;
	float SidewaysDistance;
	float TransferDuration;
	float VerticalImpulse;
}