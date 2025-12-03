class ASanctuaryBossHydraProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float Speed = 8500.0;
	ASanctuaryBossHydraHead OwningHead;
	FTransform StartTransform;
	USceneComponent TargetComponent;
	FHazeRuntimeSpline MovementSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetComponent != nullptr)
			UpdateMovementSpline();

		PerformMove(DeltaTime);
	}

	private void UpdateMovementSpline()
	{
		if (TargetComponent == nullptr)
		{
			devCheck(false, "Attempting to update movement spline, but target component isn't set.");
			return;
		}

		MovementSpline = FHazeRuntimeSpline();
		MovementSpline.AddPoint(StartTransform.Location);
		MovementSpline.AddPoint(TargetComponent.WorldLocation);
		MovementSpline.SetCustomEnterTangentPoint(StartTransform.Rotation.ForwardVector);
	}

	private void PerformMove(float DeltaTime)
	{
		float CurrentDistance = MovementSpline.GetClosestSplineDistanceToLocation(ActorLocation);
		float NextDistance = CurrentDistance + Speed * DeltaTime;
		
		FVector NextLocation;
		FRotator NextRotation;
		MovementSpline.GetLocationAndRotationAtDistance(
			NextDistance,
			NextLocation,
			NextRotation
		);
		SetActorLocationAndRotation(NextLocation, NextRotation);

		if (NextDistance >= MovementSpline.Length)
		{
			if (TargetComponent != nullptr &&
				TargetComponent.Owner != nullptr)
			{
				auto ResponseComponent = USanctuaryBossHydraResponseComponent::Get(TargetComponent.Owner);
				if (ResponseComponent != nullptr)
				{
					ResponseComponent.FireImpact(OwningHead, this);
				}
			}

			BP_ProjectileHit();
			DestroyActor();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_ProjectileHit() { }
}