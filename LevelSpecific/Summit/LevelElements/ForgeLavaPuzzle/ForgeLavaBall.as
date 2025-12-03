class AForgeLavaBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 200.0;

	UPROPERTY()
	bool bHasLost;

	FSplinePosition SplinePosition;

	UForgeLavaFlowComponent LavaFlowComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SplinePosition.Move(Speed * DeltaSeconds))
		{
			SetActorTransform(SplinePosition.WorldTransform);
		}
		else
		{
			if (LavaFlowComponent != nullptr)
				LavaFlowComponent.OnLavaFlowReachedEnd.Broadcast(this);
			else
				DestroyActor();			
		}
	}

	UFUNCTION()
	void FollowSpline(AActor ActorWithSpline)
	{
		UHazeSplineComponent Spline = UHazeSplineComponent::Get(ActorWithSpline);

		LavaFlowComponent = UForgeLavaFlowComponent::Get(ActorWithSpline);

		if (Spline == nullptr)
			return;

		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
	}
}