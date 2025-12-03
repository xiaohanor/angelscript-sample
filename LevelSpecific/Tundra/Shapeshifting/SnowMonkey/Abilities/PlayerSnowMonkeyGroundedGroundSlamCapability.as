class UTundraPlayerSnowMonkeyGroundedGroundSlamCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 44;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	USteppingMovementData Movement;
	UTundraPlayerSnowMonkeySettings GorillaSettings;
	UPlayerFloorMotionComponent FloorMotionComp;

	bool bShapeshiftBlocked = false;
	float CurrentSpeed;

	const float DurationUntilLocked = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings ::GetSettings(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SnowMonkeyComp.FrameOfStopGroundSlam == Time::FrameNumber)
			return false;

		if(Time::GetGameTimeSince(SnowMonkeyComp.TimeOfPunch) < 1.0)
			return false;

		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if(Time::GetGameTimeSeconds() - SnowMonkeyComp.TimeOfLastGroundSlam < GorillaSettings.GroundSlamCooldown)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration < GorillaSettings.GroundedGroundSlamLockedTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SnowMonkeyComp.bCurrentGroundSlamIsGrounded = true;
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamActivated(SnowMonkeyComp.SnowMonkeyActor);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		SnowMonkeyComp.bCanTriggerGroundedGroundSlam = true;

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bShapeshiftBlocked)
		{
			ShapeShiftComponent.RemoveShapeTypeBlockerInstigator(this);
			bShapeshiftBlocked = false;
		}

		SnowMonkeyComp.TimeOfLastGroundSlam = Time::GetGameTimeSeconds();
		SnowMonkeyComp.FrameOfStopGroundSlam = Time::FrameNumber;
		SnowMonkeyComp.bGroundedGroundSlamHandsHitGround = false;
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		SnowMonkeyComp.bCanTriggerGroundedGroundSlam = false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > GorillaSettings.GroundSlamShapeshiftAllowTime && !bShapeshiftBlocked)
		{
			ShapeShiftComponent.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
			bShapeshiftBlocked = true;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				CopyOfFloorMotion(DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SnowMonkeyGroundSlam");
			return;
		}
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	void CopyOfFloorMotion(float DeltaTime)
	{
		FQuat Rotation = Player.ActorQuat;
		FVector TargetDirection = MoveComp.MovementInput;
		float InputSize = MoveComp.MovementInput.Size();
		InputSize = Math::Saturate(Rotation.ForwardVector.DotProduct(MoveComp.MovementInput));
		
		if(GorillaSettings.bAllowSlamRotation)
		{
			// Interp from current forward to target forward
			const FQuat TargetForward = FQuat::MakeFromZX(Player.ActorUpVector, TargetDirection);
			Rotation = Math::QInterpTo(Rotation, TargetForward, DeltaTime, PI * 2);
		}

		float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
		float TargetSpeed = FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha);

		// Calculate the target speed
		TargetSpeed *= MoveComp.MovementSpeedMultiplier;

		if(InputSize < KINDA_SMALL_NUMBER)
			TargetSpeed = 0.0;
	
		// Update new velocity
		float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
		if(TargetSpeed < CurrentSpeed)
			InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
		CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
		float LockedAlpha = 1.0 - (ActiveDuration / DurationUntilLocked);
		FVector HorizontalVelocity = Rotation.ForwardVector.GetSafeNormal() * CurrentSpeed * LockedAlpha;

		// While on edges, we force the player of them.
		// if they have moved to far out on the edge,
		// and are not steering out from the edge
		if(MoveComp.HasUnstableGroundContactEdge())
		{
			const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
			const FVector Normal = EdgeData.EdgeNormal;
			float MoveAgainstNormal = 1 - HorizontalVelocity.GetSafeNormal().DotProduct(Normal);
			MoveAgainstNormal *= Rotation.ForwardVector.DotProductNormalized(Normal);
			float PushSpeed = Math::Clamp(HorizontalVelocity.Size(), FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, Normal * PushSpeed, MoveAgainstNormal);
		}

		Movement.AddOwnerVerticalVelocity();
		Movement.AddGravityAcceleration();
		Movement.AddHorizontalVelocity(HorizontalVelocity);
		Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.5));
		Movement.SetRotation(Rotation);
	}
}