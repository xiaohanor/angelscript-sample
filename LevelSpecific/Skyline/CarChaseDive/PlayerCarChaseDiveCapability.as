
class UPlayerCarChaseDiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 10;

    float MoveSpeed = 17000.0;
    float TopSpeed = 28000.0;

    float Acceleration = 1000.0;
    float AccelerationTimer = 1.0;
    float AccelerationInitTimer;

	UPlayerMovementComponent MoveComp;
	UPlayerCarChaseDiveComponent CarChaseDiveComp;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerLandingComponent LandingComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		CarChaseDiveComp = UPlayerCarChaseDiveComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
        if (!CarChaseDiveComp.bActive)
            return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if (!CarChaseDiveComp.bActive)
            return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);

        Player.PlaySlotAnimation(Animation = CarChaseDiveComp.DiveAnimation, bLoop = true);

		// Niagara::SpawnLoopingNiagaraSystemAttached(CarChaseDiveComp.TrailEffect, Player.RootComponent);


        // Player.ApplyCameraSettings(CarChaseDiveComp.CameraSetting, 2, this);

        // Player.OverrideGravityDirection(FVector::ForwardVector, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);

        Player.StopSlotAnimationByAsset(CarChaseDiveComp.DiveAnimation);

        // Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{

                float TargetMovementSpeed = 600.0;

				float InterpSpeed = Math::Lerp(3000.0, 5000.0, MoveComp.MovementInput.Size());
				FVector TargetSpeed = MoveComp.MovementInput * TargetMovementSpeed;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, InterpSpeed);

				Movement.AddHorizontalVelocity(HorizontalVelocity);
                Movement.AddVerticalVelocity(Player.MovementWorldUp * -MoveSpeed);
				Movement.AddPendingImpulses();

				/*
					Calculate how fast the player should rotate when falling at fast speeds
				*/
				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - CarChaseDiveComp.Settings.MaximumTurnRateFallingSpeed) / CarChaseDiveComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);
                RotationSpeedAlpha = 0.0;

				const float FacingDirectionInterpSpeed = Math::Lerp(CarChaseDiveComp.Settings.MaximumTurnRate, CarChaseDiveComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				// Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");

		}
	}

}