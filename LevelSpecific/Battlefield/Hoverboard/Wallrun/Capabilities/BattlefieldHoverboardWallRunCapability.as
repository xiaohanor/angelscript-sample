
class UBattlefieldHoverboardWallRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 34;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardWallRunComponent WallRunComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	float WallOffset = 0.0;

	UPrimitiveComponent CurrentlyFollowedComponent;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallRunComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
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
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (WasActionStarted(ActionNames::Cancel))
			return true;

		if (!WallRunComp.HasActiveWallRun())
			return true;

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
		Player.PlayCameraShake(WallRunComp.CameraShake, this);
		Player.ApplyCameraSettings(WallRunComp.CameraSettings, 0.5, this);

		WallRunComp.bCanWallRun = false;
		WallRunComp.ActiveData = ActivationParams.WallRunData;		
		WallRunComp.SetState(EPlayerWallRunState::WallRun);

		const float DistanceToWall = (Owner.ActorCenterLocation - WallRunComp.ActiveData.Location).ConstrainToDirection(WallRunComp.ActiveData.WallNormal).Size();
		WallOffset = DistanceToWall - WallRunComp.WallSettings.TargetDistanceToWall;

		Velocity = WallRunComp.ActiveData.InitialVelocity;

		//assign a component to follow
		MoveComp.FollowComponentMovement(WallRunComp.ActiveData.Component, this);
		CurrentlyFollowedComponent = WallRunComp.ActiveData.Component;

		FBattlefieldHoverboardGrindEffectParams EffectParams;
		EffectParams.AttachRootOnHoverboard = HoverboardComp.Hoverboard.RootComponent;

		UBattlefieldHoverboardEffectHandler::Trigger_OnStartedWallRun(HoverboardComp.Hoverboard, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);
		Player.StopCameraShakeByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 1.0);

		if (WallRunComp.State != EPlayerWallRunState::WallRunLedge)
			WallRunComp.StateCompleted(EPlayerWallRunState::WallRun);

		MoveComp.UnFollowComponentMovement(this);

		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(Player.ActorRotation);

		MoveComp.ClearCrumbSyncedRelativePosition(this);

		UBattlefieldHoverboardEffectHandler::Trigger_OnStoppedWallRun(HoverboardComp.Hoverboard);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
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
				
				/* Rotate Player
					- Snap if you are on the first frame
					- Interp if you are past the first frame
				*/
				FRotator TargetRotation = FRotator::MakeFromXZ(WallRunComp.ActiveData.WallRight * RunDirection, MoveComp.WorldUp);
				TargetRotation.Pitch = 0.0;
				TargetRotation.Roll = 0.0;
				FRotator Rotation;
				if (ActiveDuration > 0.0)
					Rotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, WallRunComp.Settings.FacingRotationInterpSpeed);
				else
					Rotation = TargetRotation;	

				Movement.SetRotation(Rotation);
				HoverboardComp.CameraWantedRotation = Rotation;

				ApplyHaptics(WallToPlayer);

				MoveComp.ApplyCrumbSyncedRelativePosition(this, WallRunComp.ActiveData.Component);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();

				// Update AnimData
				Velocity = MoveComp.GetCrumbSyncedPosition().WorldVelocity;
				const float RunDirection = Math::Sign(WallRunComp.ActiveData.WallRight.DotProduct(Velocity));

				WallRunComp.AnimData.RunAngle = Math::RadiansToDegrees(WallRunComp.ActiveData.WallUp.AngularDistance(Velocity.GetSafeNormal()));
				if (!Math::IsNearlyEqual(Math::Abs(WallRunComp.AnimData.RunAngle), 180.0))
					WallRunComp.AnimData.RunAngle *= RunDirection;
				WallRunComp.AnimData.bLedgeGrabbing = false;
			}
		
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardWallSliding");
		}
	}

	private void ApplyHaptics(FVector WallToPlayer)
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float BaseValue = 0.03;
		float NoiseBased = 0.01 * ((Math::PerlinNoise1D(Time::GameTimeSeconds * 2.0) + 1.0) * 0.5);
		
		float MotorStrength = (BaseValue + NoiseBased);

		bool bWallIsRight = -WallToPlayer.DotProduct(Player.ActorRightVector) > 0;
		if(bWallIsRight)
			ForceFeedBack.RightMotor = MotorStrength * 1.5;
		else
			ForceFeedBack.LeftMotor = MotorStrength;

		Player.SetFrameForceFeedback(ForceFeedBack);
	}
}