
class UPlayerWallRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 34;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallRunComponent WallRunComp;
	float WallOffset = 0.0;

	bool bLimitHeight = false;
	FVector LimitHeightLocation;

	UPrimitiveComponent CurrentlyFollowedComponent;
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallRunActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WallRunComp.HasActiveWallRun())
			return false;

		// Just make certain the data is correct when activating. This is likely redundant.
		ActivationParams.WallRunData = WallRunComp.ActiveData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerWallRunDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (WasActionStarted(ActionNames::Cancel))
			return true;

		if (!WallRunComp.HasActiveWallRun())
		{
			Params.bInvalidWallRun = true;
			return true;
		}

		if (MoveComp.IsOnAnyGround())
			return true;
		
		// If you are wall running almost vertically, you should just cancel the wall run. Why even bother mate, just give up
		if (Math::Abs(WallRunComp.AnimData.RunAngle) > 160.0)
			return true;

		// Cancel if you hit a wall that is a very different angle than the one you are on (you wall run into a wall for example)
		if (MoveComp.HasWallContact())
		{
			FVector ImpactNormal = MoveComp.WallContact.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			FVector WallNormal = WallRunComp.ActiveData.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			if (Math::RadiansToDegrees(ImpactNormal.AngularDistance(WallNormal)) >= 30.0)
				return true;
		}
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallRunActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);

		if (WallRunComp.bHasWallRunnedSinceLastGrounded)
		{
			bLimitHeight = true;
			LimitHeightLocation = WallRunComp.InitialWallRunHeightLimitLocation;
		}
		else
		{
			bLimitHeight = false;
			WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;
		}

		WallRunComp.bHasWallRunnedSinceLastGrounded = true;
		WallRunComp.LastWallRunNormal = ActivationParams.WallRunData.WallNormal;

		if(WallRunComp.State != EPlayerWallRunState::WallRunLedge)
			WallRunComp.LastWallRunStartTime = Time::GameTimeSeconds;

		WallRunComp.ActiveData = ActivationParams.WallRunData;		
		WallRunComp.SetState(EPlayerWallRunState::WallRun);

		const float DistanceToWall = (Owner.ActorCenterLocation - WallRunComp.ActiveData.Location).ConstrainToDirection(WallRunComp.ActiveData.WallNormal).Size();
		WallOffset = DistanceToWall - WallRunComp.WallSettings.TargetDistanceToWall;

		Player.SetActorVelocity(WallRunComp.ActiveData.InitialVelocity);

		//assign a component to follow
		MoveComp.FollowComponentMovement(WallRunComp.ActiveData.Component, this);
		CurrentlyFollowedComponent = WallRunComp.ActiveData.Component;

		ImpactCallbackComp = UMovementImpactCallbackComponent::Get(WallRunComp.ActiveData.Component.Owner);
		if (ImpactCallbackComp != nullptr)
			ImpactCallbackComp.AddWallAttachInstigator(Player, this);

		UPlayerCoreMovementEffectHandler::Trigger_WallRun_Started(Player);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerWallRunDeactivationParams Params)
	{	
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);

		if(WallRunComp.State == EPlayerWallRunState::WallRun && Params.bInvalidWallRun)
		{
			if(WallRunComp.PreviousData.HasValidData())
				Player.SetActorVelocity(MoveComp.Velocity + (WallRunComp.PreviousData.WallNormal * WallRunComp.Settings.InvalidWallOutwardsBoost));
			
			WallRunComp.StartTransferGraceWindow();
		}

		if (WallRunComp.State != EPlayerWallRunState::WallRunLedge)
			WallRunComp.StateCompleted(EPlayerWallRunState::WallRun);

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		if (ImpactCallbackComp != nullptr)
		{
			ImpactCallbackComp.RemoveWallAttachInstigator(Player, this);
			ImpactCallbackComp = nullptr;
		}

		UPlayerCoreMovementEffectHandler::Trigger_WallRun_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		WallRunComp.LastWallRunNormal = WallRunComp.ActiveData.WallNormal;
		if (!bLimitHeight)
			WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;

		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = Player.ActorVelocity;		

				// Calculate the angle difference of the wall to rotate the velocity around the wall
				float AngleDifference = WallRunComp.ActiveData.WallNormal.AngularDistance(WallRunComp.PreviousData.WallNormal);
				if (WallRunComp.PreviousData.HasValidData() && !Math::IsNearlyZero(AngleDifference))
				{
					FVector Axis = WallRunComp.PreviousData.WallNormal.CrossProduct(WallRunComp.ActiveData.WallNormal).GetSafeNormal();
					Velocity = FQuat(Axis, AngleDifference) * Velocity;
				}
				Velocity = Velocity.ConstrainToPlane(WallRunComp.ActiveData.WallNormal);

				// Add Gravity
				Velocity -= MoveComp.WorldUp * (WallRunComp.Settings.GravityStrength * MoveComp.GravityMultiplier) * DeltaTime;

				// Add braking on backwards input [and ensure that you can go negative speed]
				const float RunDirection = Math::Sign(WallRunComp.ActiveData.WallRight.DotProduct(Velocity));
				const float BackwardsInput = Math::Max(MoveComp.MovementInput.DotProduct(WallRunComp.ActiveData.WallRight) * -RunDirection, 0.0);
				const float ForwardSpeed = Velocity.DotProduct(WallRunComp.ActiveData.WallRight);
				float Deceleration = BackwardsInput * RunDirection * WallRunComp.Settings.HorizontalBrakingDeceleration * DeltaTime;
				if (Math::Abs(ForwardSpeed) < Deceleration)
					Deceleration = ForwardSpeed;
				Velocity -= WallRunComp.ActiveData.WallRight * Deceleration;

				Movement.AddVelocity(Velocity);

				// If we're limiting our height because of a chained wallrun, do that
				if (bLimitHeight)
				{
					float CurHeight = Player.ActorLocation.DotProduct(MoveComp.WorldUp);
					float HeightLimit = LimitHeightLocation.DotProduct(MoveComp.WorldUp);

#if !RELEASE
					TEMPORAL_LOG(this)
						.Value("bLimitHeight", bLimitHeight)
						.Value("CurHeight", CurHeight)
						.Value("HeightLimit", HeightLimit)
					;
#endif

					if (CurHeight > HeightLimit)
					{
						float PullStrength = Math::GetMappedRangeValueClamped(
							FVector2D(0.0, 400.0),
							FVector2D(0.01, 1.0),
							(CurHeight - HeightLimit)
						);

						FVector Delta = -MoveComp.WorldUp * PullStrength * WallRunComp.Settings.HeightLimitPullDownVelocity * DeltaTime;
						Movement.AddDeltaWithCustomVelocity(Delta, FVector::ZeroVector);
					}
					else
					{
						bLimitHeight = false;
					}
				}

				// Hug the wall
				WallOffset = Math::FInterpTo(WallOffset, 0.0, DeltaTime, 20.0);
				FVector WallToTarget = WallRunComp.ActiveData.WallNormal * (WallRunComp.WallSettings.TargetDistanceToWall + WallOffset);
				FVector WallToPlayer = (Owner.ActorCenterLocation - WallRunComp.ActiveData.Location).ConstrainToDirection(WallRunComp.ActiveData.WallNormal);

				FVector WallHugDelta = WallToTarget - WallToPlayer;
				Movement.AddDeltaWithCustomVelocity(WallHugDelta, FVector::ZeroVector, EMovementDeltaType::HorizontalExclusive);

				//Swap followed Component if we transition to a new one
				if (CurrentlyFollowedComponent != WallRunComp.ActiveData.Component)
				{
					MoveComp.UnFollowComponentMovement(this);
					MoveComp.FollowComponentMovement(WallRunComp.ActiveData.Component, this);
				}

				// Update AnimData
				WallRunComp.AnimData.RunAngle = Math::RadiansToDegrees(WallRunComp.ActiveData.WallUp.AngularDistance(Velocity.GetSafeNormal()));
				if (!Math::IsNearlyEqual(Math::Abs(WallRunComp.AnimData.RunAngle), 180.0))
					WallRunComp.AnimData.RunAngle *= RunDirection;
				WallRunComp.AnimData.bLedgeGrabbing = false;

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
				WallRunComp.AnimData.bLedgeGrabbing = false;
			}
		
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallRun");
		}

		if (ImpactCallbackComp != nullptr && ImpactCallbackComp.Owner != WallRunComp.ActiveData.Component.Owner)
		{
			ImpactCallbackComp.RemoveWallAttachInstigator(Player, this);
			ImpactCallbackComp = UMovementImpactCallbackComponent::Get(WallRunComp.ActiveData.Component.Owner);
			if (ImpactCallbackComp != nullptr)
				ImpactCallbackComp.AddWallAttachInstigator(Player, this);
		}
	}
}

struct FPlayerWallRunActivationParams
{
	FPlayerWallRunData WallRunData;
}

struct FPlayerWallRunDeactivationParams
{
	bool bInvalidWallRun = false;
}