struct FPlayerWallRunLedgeActivationParams
{
	FPlayerWallRunData WallRunData;
	FPlayerLedgeGrabData LedgeGrabData;
}

struct FPlayerWallRunLedgeDeactivationParams
{
	bool bWasCanceled = false;
	bool bWasWallRun = false;
	bool bInvalidWallRun = false;
};

class UPlayerWallRunLedgeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::LedgeRun);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMovement);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 33;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallRunComponent WallRunComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;
	UPrimitiveComponent CurrentlyFollowedComponent;

	float Cooldown = 0.0;
	FHazeAcceleratedVector AcceleratedLedgeOffset;

	const float TRACE_AHEAD_DURATION = 0.06;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Cooldown -= DeltaTime;

		if (IsActive() && WallRunComp.HasActiveWallRun())
			LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -WallRunComp.ActiveData.WallRotation.ForwardVector, Player.ActorLocation, WallRunComp.ActiveData.LedgeGrabData, FInstigator(this, n"LedgeRunPreTrace"), IsDebugActive());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallRunData& WallRunActivationData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (Cooldown > 0.0)
			return false;

		if (!WallRunComp.HasActiveWallRun())
			return false;	

		FPlayerLedgeGrabData LedgeGrabData;
		if (!LedgeGrabComp.TraceForLedgeGrab(Player, -WallRunComp.ActiveData.WallRotation.ForwardVector, LedgeGrabData, FInstigator(this, n"LedgeRunShouldActivate")))
			return false;

		if (!HasValidLedgeAhead())
			return false;

		if (!LedgeGrabData.TopHitComponent.HasTag(n"LedgeRunnable"))
			return false;

		// Just make certain the data is correct when activating. This is likely redundant.
		WallRunActivationData = WallRunComp.ActiveData;
		WallRunActivationData.LedgeGrabData = LedgeGrabData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerWallRunLedgeDeactivationParams& DeactivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (WasActionStarted(ActionNames::Cancel))
		{
			DeactivationParams.bWasCanceled = true;
			return true;
		}

		if (!WallRunComp.HasActiveWallRun())
		{
			DeactivationParams.bInvalidWallRun = true;
			return true;
		}

		if (!WallRunComp.ActiveData.LedgeGrabData.HasValidData())
		{
			if(WallRunComp.ActiveData.HasValidData())
				DeactivationParams.bWasWallRun = true;
			else
				DeactivationParams.bInvalidWallRun = true;

			return true;
		}
		
		if (!HasValidLedgeAhead())
		{
			if(WallRunComp.ActiveData.HasValidData())
				DeactivationParams.bWasWallRun = true;
			else
				DeactivationParams.bInvalidWallRun = true;

			return true;
		}

		if (MoveComp.IsOnAnyGround())
			return true;
		
		// Cancel if you hit a wall that is a very different angle than the one you are on (you wall run into a wall for example)
		if (MoveComp.HasWallContact())
		{
			FVector ImpactNormal = MoveComp.WallContact.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			FVector WallNormal = WallRunComp.ActiveData.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			if (Math::RadiansToDegrees(ImpactNormal.AngularDistance(WallNormal)) >= 30.0)
			{
				return true;
			}
		}
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallRunData WallRunActivationData)
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);

		if(WallRunComp.State != EPlayerWallRunState::WallRun)
			WallRunComp.LastWallRunStartTime = Time::GameTimeSeconds;

		WallRunComp.SetState(EPlayerWallRunState::WallRunLedge);
		WallRunComp.bHasWallRunnedSinceLastGrounded = true;
		WallRunComp.LastWallRunNormal = WallRunActivationData.WallNormal;
		WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;

		WallRunComp.ActiveData = WallRunActivationData;

		FVector LedgeOffset = Player.ActorLocation - WallRunComp.ActiveData.LedgeGrabData.PlayerLocation;
		FVector LedgeOffsetVelocity = MoveComp.Velocity.ConstrainToPlane(WallRunComp.ActiveData.WallRotation.RightVector);
		AcceleratedLedgeOffset.SnapTo(LedgeOffset, LedgeOffsetVelocity);

		MoveComp.FollowComponentMovement(WallRunComp.ActiveData.Component, this);
		CurrentlyFollowedComponent = WallRunComp.ActiveData.Component;

		FVector InitialVelocity = MoveComp.Velocity.ConstrainToDirection(WallRunComp.ActiveData.WallRotation.RightVector);

		//If our velocity is small enough that we cant get a clear direction (0 velocity can occur here), then we let wall aligned input decided our direction
		if(InitialVelocity.Size() < KINDA_SMALL_NUMBER)
		{
			InitialVelocity = WallRunComp.ActiveData.WallRight * (WallRunComp.ActiveData.WallRight.DotProduct(MoveComp.MovementInput.GetSafeNormal()));
		}

		Player.SetActorVelocity(InitialVelocity);

		// Ledge grabs reset airjump and airdash, so we should do the same here
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		FLedgeRunStartedEffectEventParams EffectEventParams;
		EffectEventParams.ContactHand = WallRunComp.AnimData.RunAngle < 0 ? ELeftRight::Left : ELeftRight::Right;

		UPlayerCoreMovementEffectHandler::Trigger_LedgeRun_Started(Player, EffectEventParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerWallRunLedgeDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);

		if(WallRunComp.State == EPlayerWallRunState::WallRunLedge && DeactivationParams.bInvalidWallRun)
		{
			Player.SetActorVelocity(MoveComp.Velocity + (WallRunComp.ActiveData.WallNormal * WallRunComp.Settings.InvalidWallOutwardsBoost));
			WallRunComp.StartTransferGraceWindow();
		}

		if (DeactivationParams.bWasCanceled)
		{
			WallRunComp.ActiveData.InitialVelocity = MoveComp.Velocity;
			Cooldown = 1.0;
		}
		else if (DeactivationParams.bWasWallRun)
		{
			WallRunComp.ActiveData.InitialVelocity = MoveComp.Velocity;
		}
		else
			WallRunComp.StateCompleted(EPlayerWallRunState::WallRunLedge);

		MoveComp.ClearCrumbSyncedRelativePosition(this);

		MoveComp.UnFollowComponentMovement(this);

		if(DeactivationParams.bWasCanceled)
		{
			UPlayerCoreMovementEffectHandler::Trigger_LedgeRun_Cancel(Player);
		}
		
		UPlayerCoreMovementEffectHandler::Trigger_LedgeRun_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		WallRunComp.LastWallRunNormal = WallRunComp.ActiveData.WallNormal;
		WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;

		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = Player.ActorVelocity;
				float Speed = Math::FInterpTo(Velocity.Size(), WallRunComp.Settings.LedgeGrabTargetSpeed, DeltaTime, WallRunComp.Settings.LedgeGrabTargetSpeedInterpSpeed);

				// Redirect velocity along the ledge
				Velocity = WallRunComp.ActiveData.LedgeGrabData.LedgeRightVector * Speed * Math::Sign(WallRunComp.ActiveData.LedgeGrabData.LedgeRightVector.DotProduct(Velocity));
				Movement.AddVelocity(Velocity);

				// Update offset
				AcceleratedLedgeOffset.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);
				FVector LedgeOffset = Player.ActorLocation - WallRunComp.ActiveData.LedgeGrabData.PlayerLocation;
				FVector LedgeOffsetDelta = AcceleratedLedgeOffset.Value - LedgeOffset;
				Movement.AddDeltaWithCustomVelocity(LedgeOffsetDelta, FVector::ZeroVector);

				//Swap followed Component if we transition to a new one
				if (CurrentlyFollowedComponent != WallRunComp.ActiveData.Component)
				{
					MoveComp.UnFollowComponentMovement(this);
					MoveComp.FollowComponentMovement(WallRunComp.ActiveData.Component, this);
				}

				// Update AnimData
				WallRunComp.AnimData.RunAngle = Math::RadiansToDegrees(WallRunComp.ActiveData.WallUp.AngularDistance(Velocity.GetSafeNormal()));
				float RunDirection = Math::Sign(WallRunComp.ActiveData.WallRight.DotProduct(Velocity));
				if (!Math::IsNearlyEqual(Math::Abs(WallRunComp.AnimData.RunAngle), 180.0))
					WallRunComp.AnimData.RunAngle *= RunDirection;
				WallRunComp.AnimData.bLedgeGrabbing = true;

				// Force feedback!
				float LeftFF = 0.0;
				float RightFF = 0.0;
				if (Math::IsNearlyEqual(RunDirection, 1.0))
					RightFF = 1.0;
				else
					LeftFF = 1.0;

				float FFMultiplier = Math::Sin(-ActiveDuration * 50) * 0.1;

				Player.SetFrameForceFeedback(LeftFF * FFMultiplier, RightFF * FFMultiplier, 0.0, 0.0);
				
				/* Rotate Player
					- Snap if you are on the first frame
					- Interp if you are past the first frame
				*/
				FRotator TargetRotation = FRotator::MakeFromXZ(WallRunComp.ActiveData.WallRight * RunDirection, MoveComp.WorldUp);
				if (ActiveDuration > 0.0)
				{
					TargetRotation.Pitch = 0.0;
					Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, WallRunComp.Settings.FacingRotationInterpSpeed));
				}
				else
					Movement.SetRotation(TargetRotation);

				MoveComp.ApplyCrumbSyncedRelativePosition(this, WallRunComp.ActiveData.Component);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();

				// Update AnimData
				FVector Velocity = MoveComp.GetCrumbSyncedPosition().WorldVelocity;
				const float RunDirection = Math::Sign(WallRunComp.ActiveData.WallRight.DotProduct(Velocity));

				WallRunComp.AnimData.RunAngle = Math::RadiansToDegrees(WallRunComp.ActiveData.WallUp.AngularDistance(Velocity.GetSafeNormal()));
				if (!Math::IsNearlyEqual(Math::Abs(WallRunComp.AnimData.RunAngle), 180.0))
					WallRunComp.AnimData.RunAngle *= RunDirection;
				WallRunComp.AnimData.bLedgeGrabbing = true;
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallRun");
		}
	}

	//
	bool HasValidLedgeAhead() const
	{
		FPlayerLedgeGrabData TestData;

		if(LedgeGrabComp.TraceForLedgeGrabAtLocation(Player,
			 -WallRunComp.ActiveData.WallRotation.ForwardVector,
			 	 Player.ActorLocation + (Player.ActorForwardVector.ConstrainToPlane(-WallRunComp.ActiveData.WallRotation.ForwardVector) * (WallRunComp.Settings.LedgeGrabTargetSpeed * TRACE_AHEAD_DURATION)),
				 	 TestData, FInstigator(this, n"LedgeEndTrace"), false))
		{
			TestData.HasValidData();
			return true;
		}

		return false;
	}
}