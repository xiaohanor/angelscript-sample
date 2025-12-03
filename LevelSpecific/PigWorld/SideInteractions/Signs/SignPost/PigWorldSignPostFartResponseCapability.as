class UPigWorldSignPostFartResponseCapability : UHazeCapability
{
	APigWorldSignPost SignPost;
	UPigRainbowFartResponseComponent FartResponseComponent;

	FPigRainbowFartMovementResponseData MovementResponseData;

	const float AccelerationDuration = 0.1;

	float RotationDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SignPost = Cast<APigWorldSignPost>(Owner);
		FartResponseComponent = UPigRainbowFartResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (FartResponseComponent == nullptr)
			return false;

		if (!SignPost.bFartedOn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= MovementResponseData.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazePlayerCharacter Player = FartResponseComponent.PlayersInTrigger.Last();
		MovementResponseData = FartResponseComponent.MovementResponseData;

		// Determine direction of rotation
		FVector PlayerToSign = (SignPost.ActorLocation - Player.ActorLocation).ConstrainToPlane(MovementResponseData.GetRotationAxisForComponent(SignPost.MovementRoot));
		FVector CrossAxis = MovementResponseData.GetCrossRotationAxisForComponent(Player.RootComponent);
		RotationDirection = Math::Sign(PlayerToSign.DotProduct(CrossAxis));

		// Wiggle stuff
		AcceleratedWiggle.SnapTo(FartResponseComponent.MovementResponseData.GetRotatorWithAmount(FartResponseComponent.MovementResponseData.WiggleMaxAngle));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SignPost.bFartedOn = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch (MovementResponseData.MovementType)
		{
			case EPigRainbowFartMovementResponseType::Rotation: TickRotation(DeltaTime); 	break;
			case EPigRainbowFartMovementResponseType::Wiggle:	TickWiggle(DeltaTime);		break;
		}
	}

	void TickRotation(float DeltaTime)
	{
		// Accelerate into speed
		float SpeedMultiplier = Math::Saturate(ActiveDuration / AccelerationDuration);

		// Decelerate
		SpeedMultiplier -= Math::Pow(Math::Saturate((ActiveDuration - AccelerationDuration) / MovementResponseData.Duration), 1.2);

		// FVector Axis = MovementResponseData.GetRotationAxisForComponent(SignPost.MovementRoot);

		// FQuat Rotation = FQuat(Axis, Angle * SpeedMultiplier);
		float Angle = MovementResponseData.RotationSpeed * RotationDirection;
		FRotator Rotation = FartResponseComponent.MovementResponseData.GetRotatorWithAmount(Angle * SpeedMultiplier);

		SignPost.MovementRoot.AddLocalRotation(Rotation);
	}

	FHazeAcceleratedRotator AcceleratedWiggle;

	void TickWiggle(float DeltaTime)
	{
		// float SpeedMultiplier = 1.0 - Math::Pow(Math::Saturate(ActiveDuration / MovementResponseData.Duration), 1.2);
		// float TargetSpeed = MovementResponseData.Speed * SpeedMultiplier;

		AcceleratedWiggle.SpringTo(FRotator(), 80, 0.01, DeltaTime);

		float Fraction = Math::Saturate(ActiveDuration / 0.2);
		FRotator Rotation = Math::LerpShortestPath(FRotator(), AcceleratedWiggle.Value, Fraction);
		SignPost.MovementRoot.SetRelativeRotation(Rotation);
	}
}