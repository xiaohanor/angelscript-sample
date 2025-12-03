class ALiftSectionSponge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = false;
		UPROPERTY(EditAnywhere)
	bool bActive = bActiveFromStart;

	float CurrentDistanceAlongSpline = 0.0;

	FVector StartLocation = ActorLocation;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 2000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(TargetSplineActor);
		if (SplineComp != nullptr)
		{
			//SetActorLocation(SplineComp.GetClosestSplineWorldLocationToWorldLocation(ActorLocation));
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
			bActive = true;
		}
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateSpline()
	{
		CurrentDistanceAlongSpline = 0.0;
		SetActorTickEnabled(true);
		bActive = true;
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintCallable)
	void StopSpline()
	{
		CurrentDistanceAlongSpline = 0.0;
		SetActorTickEnabled(false);
		bActive = false;
		//SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintCallable)
	void ReturnToStartLocation()
	{
		StopSpline();
		ActorLocation = StartLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			CurrentDistanceAlongSpline += MovementSpeed * DeltaTime;
			if (CurrentDistanceAlongSpline >= TargetSplineComp.SplineLength)
			{
				CurrentDistanceAlongSpline = 0;
			}

			FVector CurLoc = TargetSplineComp.GetWorldLocationAtSplineDistance(CurrentDistanceAlongSpline);
			FRotator CurRot = FRotator(TargetSplineComp.GetWorldRotationAtSplineDistance(CurrentDistanceAlongSpline));
			SetActorLocation(CurLoc);
		}
	}
}