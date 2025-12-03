class USanctuaryWeeperLightBirdMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;
	
	ASanctuaryWeeperLightBird LightBird;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	float MovementSpeed;
	FVector MovementDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementSpeed = MoveComp.HorizontalVelocity.Size();
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FVector InputDirection = MoveComp.MovementInput;
			float InputSize = InputDirection.Size();

			// Figure out what our maximum speed is
			float MaximumSpeed = 0.0;
			if (InputSize > KINDA_SMALL_NUMBER)
			{
				InputSize = Math::Max(LightBird.MinInputSize, InputSize);

				if (!LightBird.IsIlluminating())
					MaximumSpeed = LightBird.MovementSpeed * InputSize;
				else
					MaximumSpeed = LightBird.IlluminateMovementSpeed * InputSize;
			}

			// Acceleration/deceleration speed determined by direction towards maximum
			float InterpSpeed = LightBird.Acceleration;
			if (MovementSpeed < MaximumSpeed)
				InterpSpeed = LightBird.Deceleration;

			// Constant interpolation towards maximum speed
			MovementSpeed = Math::FInterpConstantTo(MovementSpeed, MaximumSpeed, DeltaTime, InterpSpeed);

			// Speed is applied as velocity horizontally
			// NOTE: Input direction is normalized here since movement speed is scaled by input size
			FVector HorizontalVelocity = InputDirection.GetSafeNormal() * MovementSpeed;

			// Movement.AddGravityAcceleration();
			// Movement.AddOwnerVerticalVelocity();
			Movement.AddHorizontalVelocity(HorizontalVelocity);
			Movement.InterpRotationToTargetFacingRotation(LightBird.FacingInterpSpeed);
			MoveComp.ApplyMove(Movement);
		}
	}
}