class ASanctuaryBossSlideBall : AActorAlignedToSpline
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ScalingPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotatingPivot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	float Speed = -1000.0;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 90.0;
	float CurrentRotation = 0.0;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	AActor ActorWithSpline;
	UHazeSplineComponent Spline;

	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		if (ActorWithSpline != nullptr)
		{
			Spline = UHazeSplineComponent::Get(ActorWithSpline);

			SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		}

		if (PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		}

		ImpactComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"HandleImpact");
		ImpactComp.OnWallImpactedByPlayer.AddUFunction(this, n"HandleImpact");
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePosition.Move(Speed * DeltaSeconds);

//		CurrentRotation += RotationSpeed * DeltaSeconds;

//		FQuat Rotation = FQuat(SplinePosition.WorldRotation.ForwardVector, Math::DegreesToRadians(CurrentRotation)) * SplinePosition.WorldRotation;

//		FTransform Transform = SplinePosition.WorldTransform;
//		Transform.Rotation = Rotation;

		RotatingPivot.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));

		ScalingPivot.WorldScale3D = SplinePosition.WorldScale3D;

		SetActorLocationAndRotation(
			SplinePosition.WorldLocation,
			SplinePosition.WorldRotation
		);			
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleImpact(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
	}
};