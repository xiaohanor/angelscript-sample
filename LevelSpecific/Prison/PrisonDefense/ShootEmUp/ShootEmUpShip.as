class AShootEmUpShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShipRoot;

	UPROPERTY(DefaultComponent, Attach = ShipRoot)
	UStaticMeshComponent ShipMesh;

	UPROPERTY(DefaultComponent, Attach = ShipMesh)
	USceneComponent ShotRoot;

	float PlayerInput = 0.0;
	float InterpedInput = 0.0;

	float CurrentHeight = 0.0;
	float MaxHeight = 1600.0;

	float MoveSpeed = 2000.0;

	float SplineDist = 0.0;
	UHazeSplineComponent SplineComp;
	float SplineSpeed = 3500.0;

	void UpdatePlayerInput(FVector2D Input)
	{
		PlayerInput = Input.X;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		InterpedInput = Math::FInterpTo(InterpedInput, PlayerInput, DeltaTime, 6.0);

		CurrentHeight += InterpedInput * MoveSpeed * DeltaTime;
		CurrentHeight = Math::Clamp(CurrentHeight, -MaxHeight, MaxHeight);
		ShipRoot.SetRelativeLocation(FVector(0.0, 0.0, CurrentHeight));

		float Rot = InterpedInput * 500.0 * DeltaTime;
		ShipRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));

		float ZOffset = Math::Sin(Time::GameTimeSeconds * 2.5) * 20.0;
		ShipMesh.SetRelativeLocation(FVector(0.0, 0.0, ZOffset));

		if (SplineComp != nullptr)
		{
			SplineDist += SplineSpeed * DeltaTime;
			SetActorLocation(SplineComp.GetWorldLocationAtSplineDistance(SplineDist));
			SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(SplineDist));
		}
	}

	UFUNCTION()
	void StartFollowingSpline(AHazeActor SplineActor)
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);
	}

	UFUNCTION()
	void UpdateSpeed(float NewSpeed)
	{
		SplineSpeed = NewSpeed;
	}
}