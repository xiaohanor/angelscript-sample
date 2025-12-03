class UAdultDragonChaseStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragonChaseStrafeCapability");
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 10;

	default DebugCategory = n"AdultDragon";

	UPlayerMovementComponent MoveComp;
	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonChaseStrafeComponent ChaseStrafeComp; 
	USteppingMovementData Movement;
	UAdultDragonFlightSettings FlightSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		ChaseStrafeComp = UAdultDragonChaseStrafeComponent::Get(Player);

		Movement = MoveComp.SetupSteppingMovementData();
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ChaseStrafeComp.bCanChaseStrafe)
			return false;
		
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

		UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ChaseStrafeComp.bCanChaseStrafe)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"AdultDragonFlying", this);
		Player.BlockCapabilities(n"Steering", this);
		// SpeedEffect::RequestSpeedEffect(Player, 0.35, this, EInstigatePriority::High);
		Player.PlayCameraShake(ChaseStrafeComp.ChaseCameraShake, this, 0.75);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"AdultDragonFlying", this);
		Player.UnblockCapabilities(n"Steering", this);
		// SpeedEffect::ClearSpeedEffect(Player, this);
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				float SpeedTarget = Input.X * 7000.0;
				DragonComp.Speed = Math::FInterpConstantTo(DragonComp.Speed, SpeedTarget, DeltaTime, 8000.0);

				FVector Velocity = Player.ActorRightVector * DragonComp.Speed;
				Velocity += ChaseStrafeComp.ForwardDirection * FlightSettings.MaxSpeed;
				Movement.AddDelta(Velocity * DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			// MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AdultDragonFlying");
		}
	}

}