class UBattlefieldHoverboardAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardLevelRubberbandingComponent LevelRubberbandingComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardAirMovementSettings AirMovementSettings;
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;
	UBattlefieldHoverboardJumpSettings JumpSettings;
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	float HorizontalSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		AirMovementSettings = UBattlefieldHoverboardAirMovementSettings::GetSettings(Player);
		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector Velocity = Player.ActorVelocity + MoveComp.PendingImpulse;
		
		bool bIsGoingUpwards = Velocity.DotProduct(MoveComp.WorldUp) > 0.0;
		FVector VerticalVelocityDir = bIsGoingUpwards ? MoveComp.WorldUp : MoveComp.GravityDirection;
		FVector VerticalVelocity = Velocity.ConstrainToDirection(VerticalVelocityDir);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		TEMPORAL_LOG(Player, "Hoverboard Air Movement")
			.DirectionalArrow("Vertical Velocity", Player.ActorLocation, VerticalVelocity, 5, 40, FLinearColor::Blue)
			.DirectionalArrow("Horizontal Velocity", Player.ActorLocation, HorizontalVelocity, 5, 40, FLinearColor::Red)
		;

		HorizontalSpeed = HorizontalVelocity.Size();

		if(JumpComp.bJumped)
			JumpComp.bAirborneFromJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.bAirborneFromJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;
				float InputSize = MovementInput.Size();

				UpdateRotation(DeltaTime, MovementInput);
				Movement.SetRotation(HoverboardComp.AccNudgeRotation.Value + HoverboardComp.AccRotation.Value);

				FRotator VelocityRot = GetVelocityRotation();
				FVector PreviousForwardVelocity = MoveComp.Velocity.ConstrainToDirection(VelocityRot.ForwardVector);
				FVector SidewaysVelocity = MoveComp.Velocity - MoveComp.VerticalVelocity - PreviousForwardVelocity;
				SidewaysVelocity = Math::VInterpTo(SidewaysVelocity, FVector::ZeroVector, DeltaTime, 10);
				Movement.AddVelocity(SidewaysVelocity);
				VelocityRot = RotateVelocityRotation(VelocityRot, DeltaTime, InputSize);				
				HorizontalSpeed = UpdateHorizontalSpeed(DeltaTime);
				float TotalSpeed = (HorizontalSpeed + LevelRubberbandingComp.RubberbandingSpeed + HoverboardComp.TrickBoostSpeed) * MoveComp.GetMovementSpeedMultiplier();
				
				if(!BattlefieldDevToggles::FreezeMovement.IsEnabled())
					Movement.AddHorizontalVelocity(VelocityRot.ForwardVector * TotalSpeed);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				HoverboardComp.AnimParams.VerticalSpeedWhileAirborne = MoveComp.VerticalSpeed;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardAirMovement;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	private FRotator GetVelocityRotation()
	{
		FRotator VelocityRot;
		if(Player.ActorHorizontalVelocity.IsNearlyZero())
			VelocityRot = HoverboardComp.AccRotation.Value;
		else
			VelocityRot = Player.ActorHorizontalVelocity.Rotation();

		return VelocityRot;
	}	

	private FRotator RotateVelocityRotation(FRotator VelocityRot, float DeltaTime, float InputSize)
	{
		float TurnSpeed = AirMovementSettings.HorizontalConstantVelocityTurnSpeed + AirMovementSettings.HorizontalInputVelocityTurnSpeed * InputSize;
		FRotator RotatedVelocityRot = Math::RInterpConstantTo(VelocityRot, HoverboardComp.AccRotation.Value, DeltaTime, TurnSpeed);

		return RotatedVelocityRot;
	}

	private float UpdateHorizontalSpeed(float DeltaTime)
	{
		HorizontalSpeed = Math::FInterpConstantTo(HorizontalSpeed, AirMovementSettings.MaxHorizontalSpeed, DeltaTime, AirMovementSettings.HorizontalAcceleration);
		return HorizontalSpeed;
	}

	private void UpdateRotation(float DeltaTime, FVector MovementInput)
	{
		HoverboardComp.AddWantedRotation(AirMovementSettings.WantedRotationSpeed, MovementInput, DeltaTime);
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
		float TargetRotationDuration = MovementInput.IsNearlyZero() 
			? AirMovementSettings.RotationDuration 
			: AirMovementSettings.RotationDurationDuringInput;
		HoverboardComp.RotateTowardsWantedRotation(TargetRotationDuration, DeltaTime);
	}
};