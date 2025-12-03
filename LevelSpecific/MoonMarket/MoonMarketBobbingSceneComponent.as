class UMoonMarketBobbingSceneComponent : USceneComponent
{
	FVector StartLocation;
	UPROPERTY(EditAnywhere)
	float BobAmount = 10.0;
	float Speed;

	UPROPERTY(EditAnywhere)
	float MinBobSpeed = 0.25;

	UPROPERTY(EditAnywhere)
	float MaxBobSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	bool bIsEnabled = true;

	float CircleMaxSpeed = 0.2;
	float CircleRadius = 10;
	float RandomCircleOffset;

	FHazeAcceleratedFloat CurrentWeight;
	float WeightTargetOffset = 0;
	float SpringStiffness = 50;
	float SpringDamping = 0.1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = RelativeLocation;
		Speed = Math::RandRange(MinBobSpeed, MaxBobSpeed);
		RandomCircleOffset = Math::RandRange(0, 1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsEnabled)
			return;

		CurrentWeight.SpringTo(WeightTargetOffset, SpringStiffness, SpringDamping, DeltaSeconds);

		float VerticalBobAdd = Math::Sin(Time::GameTimeSeconds * Speed) * BobAmount;
		float Angle = (((Time::GameTimeSeconds + RandomCircleOffset) * CircleMaxSpeed * Speed) % 2) * 360.0;
		FVector NewLocation = StartLocation + FVector::RightVector.RotateAngleAxis(Angle, FVector::UpVector) * CircleRadius;
		NewLocation += FVector::UpVector * (VerticalBobAdd + CurrentWeight.Value);
		RelativeLocation = NewLocation;
	}
};