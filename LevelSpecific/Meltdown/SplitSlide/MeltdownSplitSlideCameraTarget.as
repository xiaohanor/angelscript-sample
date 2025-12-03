class AMeltdownSplitSlideCameraTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	float DefaultDistanceOffset = 600.0;

	FHazeAcceleratedFloat AcceleratedDistanceOffset;
	float TargetDistanceOffset;

	float SplineProgress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (AttachParentActor != nullptr)
			Spline = UHazeSplineComponent::Get(AttachParentActor);

		TargetDistanceOffset = DefaultDistanceOffset;
		AcceleratedDistanceOffset.SnapTo(TargetDistanceOffset);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedDistanceOffset.AccelerateTo(TargetDistanceOffset, 3.0, DeltaSeconds);

		float ShortestSplineDistance = BIG_NUMBER;

		for (auto Player : Game::Players)
		{
			if (!Player.IsPlayerDead())
			{
				float PlayerSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
				if (PlayerSplineDistance < ShortestSplineDistance)
					ShortestSplineDistance = PlayerSplineDistance;
			}
		}

		if (ShortestSplineDistance > SplineProgress && ShortestSplineDistance < BIG_NUMBER)
			SplineProgress = ShortestSplineDistance;

		SetActorLocation(Spline.GetWorldLocationAtSplineDistance(SplineProgress + AcceleratedDistanceOffset.Value));
	}

	UFUNCTION()
	void SetTargetDistanceOffset(float DistanceOffset)
	{
		TargetDistanceOffset = DistanceOffset;
	}
};