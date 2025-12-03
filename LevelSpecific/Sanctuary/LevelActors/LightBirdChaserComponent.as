class ULightBirdChaserComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	float Speed = 400.0;

	UPROPERTY(EditAnywhere)
	float DetectionRange = 3000.0;

	UPROPERTY(EditAnywhere)
	float MaximumReach = 2000.0;

	UPROPERTY(EditAnywhere)
	float LightBirdOffset = 250.0;

	UPROPERTY(EditAnywhere)
	float MaximumReturnDelay = 2.0;

	float ReturnDelay = 0.0;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetSpeedMultiplier = 0.0;

	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComponent = UDarkPortalResponseComponent::GetOrCreate(Owner);
	}

	void Update(float DeltaSeconds)
	{
		auto LightBirdUserComponent = ULightBirdUserComponent::Get(Game::Mio);
		FVector BirdLocation = LightBirdUserComponent.GetLightBirdLocation();

		// Will rewrite this..

		FVector OriginToLightBird = BirdLocation - Owner.ActorLocation;
		FVector ToLightBird = BirdLocation - WorldLocation;
		FVector ToOrigin = Owner.ActorLocation - WorldLocation;
		FVector MoveDirection = ForwardVector;

		if (LightBirdUserComponent.IsIlluminating() && OriginToLightBird.Size() <= DetectionRange)
		{
			ReturnDelay = Math::Min(MaximumReturnDelay, ReturnDelay + DeltaSeconds);
			TargetSpeedMultiplier = 1.0;
			MoveDirection = ToLightBird.GetSafeNormal();
		}
		else
		{
			ReturnDelay = Math::Max(0.0, ReturnDelay - DeltaSeconds);
			TargetSpeedMultiplier = -1.0;
			MoveDirection = -ToOrigin.GetSafeNormal();
		}

		if (!LightBirdUserComponent.IsIlluminating() && ReturnDelay > 0.0)
			TargetSpeedMultiplier = 0.0;

		FVector LookDirection = MoveDirection;

		AcceleratedFloat.AccelerateTo(TargetSpeedMultiplier, 1.0, DeltaSeconds);
		FVector DeltaMove = MoveDirection * AcceleratedFloat.Value * Speed * DeltaSeconds;

		// Reached LightBird
		if (LightBirdUserComponent.IsIlluminating() && (WorldLocation - BirdLocation).Size() < LightBirdOffset)
		{
			AcceleratedFloat.SnapTo(0.0);
			DeltaMove = FVector::ZeroVector;
			LookDirection = ForwardVector;
		}

		// Returned
		if (!LightBirdUserComponent.IsIlluminating() && (WorldLocation - Owner.ActorLocation).Size() < 5.0)
		{
			AcceleratedFloat.SnapTo(0.0);
			DeltaMove = FVector::ZeroVector;
			LookDirection = Owner.ActorForwardVector;
		}

		// Update Location
		AddWorldOffset(DeltaMove);

		FVector FromOrigin = WorldLocation - Owner.ActorLocation;
		if (FromOrigin.Size() > MaximumReach)
			SetWorldLocation(Owner.ActorLocation + FromOrigin.GetSafeNormal() * MaximumReach);

		// Update Rotation
		SetWorldRotation(FQuat::Slerp(ComponentQuat, LookDirection.ToOrientationQuat(), DeltaSeconds * 5.0));
	}
}