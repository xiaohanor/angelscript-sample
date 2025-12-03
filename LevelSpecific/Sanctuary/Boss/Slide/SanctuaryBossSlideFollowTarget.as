class ASanctuaryBossSlideFollowTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AActor ActorWithSpline;
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	float DistanceOffset = 600.0;

	UPROPERTY(EditAnywhere)
	FVector FocusTargetOffset = FVector(0.0, 0.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorWithSpline != nullptr)
			Spline = UHazeSplineComponent::Get(ActorWithSpline);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FSplinePosition TargetPosition;
		for (auto Player : Game::Players)
		{
			auto PlayerSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
			if (!TargetPosition.IsValid() || TargetPosition.CanReach(PlayerSplinePosition, ESplineMovementPolarity::Positive))
				TargetPosition = PlayerSplinePosition;
		}

		TargetPosition.Move(DistanceOffset);

		FTransform Transform = TargetPosition.WorldTransform;
		Transform.Location = Transform.Location + Transform.TransformVectorNoScale(FocusTargetOffset);

		SetActorLocationAndRotation(
			Transform.Location,
			Transform.Rotation
		);
	}
};