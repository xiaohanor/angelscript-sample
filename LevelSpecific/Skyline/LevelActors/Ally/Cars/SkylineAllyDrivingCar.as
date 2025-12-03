class ASkylineAllyDrivingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;
	float DistanceAlongSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(EditAnywhere)
	float Speed = 10000.0;
	
	bool bDriving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	void Activate()
	{
		DistanceAlongSpline = 0.0;
		RemoveActorDisable(this);
		bDriving = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		AddActorDisable(this);
		bDriving = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDriving)
		{
			if (DistanceAlongSpline < SplineComp.SplineLength)
				DistanceAlongSpline += Speed * DeltaSeconds;

			else
				Deactivate();

			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
			FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(DistanceAlongSpline);
			CarRoot.SetWorldLocationAndRotation(Location, Rotation);
		}
	}
};