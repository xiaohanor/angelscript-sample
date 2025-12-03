class ULightBirdWeeperMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(LightBird::Tags::LightBird);


	default TickGroup = EHazeTickGroup::Gameplay;



	UHazeMovementComponent MoveComp;

	float HorizontalInput;
	float VerticalInput;
	float MoveSpeed = 350;

	USteppingMovementData Movement;

	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);

		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveDirection = MoveComp.MovementInput;
		FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		FVector CameraDirection = FVector(-CameraInput.X, CameraInput.Y, 0);


		if(MoveComp.PrepareMove(Movement))
		{
			Movement.AddHorizontalVelocity(MoveDirection * MoveSpeed);
		}

		MoveComp.ApplyMove(Movement);


	}
};