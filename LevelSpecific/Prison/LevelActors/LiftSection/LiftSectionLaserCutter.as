class ALiftSectionLaserCutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = false;
	bool bActive = bActiveFromStart;

	float CurrentDistanceAlongSpline = 0.0;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(TargetSplineActor);
		if (SplineComp != nullptr)
		{
			SetActorTransform(SplineComp.GetClosestSplineWorldTransformToWorldLocation(ActorLocation));
		}
	}



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetSplineComp = TargetSplineActor.Spline;

		if (bActiveFromStart)
		{
			CurrentDistanceAlongSpline = TargetSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintCallable)
	void ActivateLaser()
	{
		CurrentDistanceAlongSpline = 0.0;
		SetActorTickEnabled(true);
		bActive = true;
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
		CurrentDistanceAlongSpline += MovementSpeed * DeltaTime;
		if (CurrentDistanceAlongSpline >= TargetSplineComp.SplineLength)
		{
			bActive = false;
			SetActorHiddenInGame(true);
		}

		FVector CurLoc = TargetSplineComp.GetWorldLocationAtSplineDistance(CurrentDistanceAlongSpline);
		FRotator CurRot = FRotator(TargetSplineComp.GetWorldRotationAtSplineDistance(CurrentDistanceAlongSpline));

		SetActorLocationAndRotation(CurLoc, CurRot);
		}
	}
}