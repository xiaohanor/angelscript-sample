class UBattlefieldHoverboardForcedImpulseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardAirMovementSettings AirMovementSettings;
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		AirMovementSettings = UBattlefieldHoverboardAirMovementSettings::GetSettings(Player);
		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(!MoveComp.HasImpulse())
			return false;

		FVector ForcedImpulse = MoveComp.GetPendingImpulseWithInstigator(n"Forced");
		if(ForcedImpulse.IsNearlyZero())
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

		if(MoveComp.IsOnWalkableGround()
		&& ActiveDuration > 0.2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(JumpComp.bJumped)
			JumpComp.bAirborneFromJump = true;

		Player.SetActorVelocity(FVector::ZeroVector);
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
				Movement.AddPendingImpulses();
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();

				FVector MovementInput = MoveComp.MovementInput;
				float InputSize = MovementInput.Size();

				UpdateRotation(DeltaTime, MovementInput);
				Movement.SetRotation(HoverboardComp.AccNudgeRotation.Value + HoverboardComp.AccRotation.Value);

				FRotator VelocityRot = GetVelocityRotation();
				VelocityRot = RotateVelocityRotation(VelocityRot, DeltaTime, InputSize);
				
				HoverboardComp.AnimParams.VerticalSpeedWhileAirborne = MoveComp.VerticalSpeed;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = n"HoverboardAirMovement";
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