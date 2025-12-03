
class UMagneticFieldPlayerPostLaunchAirMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerLandingComponent LandingComp;
	USteppingMovementData Movement;

	UMagneticFieldPlayerComponent MagneticFieldPlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);

		MagneticFieldPlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!MagneticFieldPlayerComp.IsLaunched())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!MagneticFieldPlayerComp.IsLaunched())
			return true;

		if(MoveComp.VerticalSpeed < 0.0)
			return true;

		// Disable this air motion if we are moving down or have hit the ground
		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Disable regular AirMotion while active
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		MagneticFieldPlayerComp.LaunchDatas.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			float TargetMovementSpeed = JogComp.Settings.MaximumSpeed + 150.0;
			if (SprintComp.IsSprintToggled())
				TargetMovementSpeed = SprintComp.Settings.MaximumSpeed;

			TargetMovementSpeed *= MoveComp.MovementSpeedMultiplier;

			// Only allow side-to-side movement
			const FVector SideInput = GetSideInput();
			const FVector TargetSpeed = SideInput * TargetMovementSpeed;
			const FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, 450.0);

			Movement.AddHorizontalVelocity(HorizontalVelocity);

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();				
			Movement.AddPendingImpulses();

			/*
				Calculate how fast the player should rotate when falling at fast speeds
			*/
			const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
			const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

			const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
			Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		Movement.RequestFallingForThisFrame();
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
	}

	private FVector GetSideInput() const
	{
		if(MoveComp.MovementInput.IsNearlyZero())
			return FVector::ZeroVector;

		if(MoveComp.Velocity.IsNearlyZero())
			return FVector::ZeroVector;

		FVector Forward = MoveComp.Velocity.VectorPlaneProject(FVector::UpVector);
		if(Forward.IsNearlyZero())
			return FVector::ZeroVector;

		FVector Right = Forward.CrossProduct(FVector::UpVector).GetSafeNormal();
		if(Right.IsNearlyZero())
			return FVector::ZeroVector;

		return MoveComp.MovementInput.ProjectOnToNormal(Right);
	}
}