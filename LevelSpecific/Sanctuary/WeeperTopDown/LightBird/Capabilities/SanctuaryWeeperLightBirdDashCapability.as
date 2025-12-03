class USanctuaryWeeperLightBirdDashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 105;


	UHazeMovementComponent MoveComp;
	ASanctuaryWeeperLightBird LightBird;
	USteppingMovementData Movement;
	float MovementSpeed;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);	
		Movement = MoveComp.SetupSteppingMovementData();
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		if(LightBird.bIsDashOnCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		if(ActiveDuration >= LightBird.DashDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightBird.bIsDashOnCooldown = true;
		LightBird.bIsDashing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightBird.TimeToEnableDash = Time::GameTimeSeconds + LightBird.DashCooldownDuration;
		LightBird.bIsDashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FVector InputDirection = MoveComp.MovementInput;
			float InputSize = InputDirection.Size();

			// Figure out what our maximum speed is
			float MaximumSpeed = LightBird.DashMovementSpeed;

			// Acceleration/deceleration speed determined by direction towards maximum
			float InterpSpeed = LightBird.Acceleration;

			// Constant interpolation towards maximum speed
			MovementSpeed = Math::FInterpConstantTo(MovementSpeed, MaximumSpeed, DeltaTime, InterpSpeed);

			// Speed is applied as velocity horizontally
			// NOTE: Input direction is normalized here since movement speed is scaled by input size
			FVector HorizontalVelocity = LightBird.ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * MaximumSpeed;



			// Movement.AddGravityAcceleration();
			// Movement.AddOwnerVerticalVelocity();
			Movement.AddHorizontalVelocity(HorizontalVelocity);
			Movement.InterpRotationToTargetFacingRotation(LightBird.FacingInterpSpeed * 1);
			MoveComp.ApplyMove(Movement);
		}
	}
};