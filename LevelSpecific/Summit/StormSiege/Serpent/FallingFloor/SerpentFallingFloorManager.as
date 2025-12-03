class ASerpentFallingFloorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	TArray<ASerpentFallingFloor> FallingFloorArray;

	FSplinePosition SplinePos;

	float Speed = 310.0;
	float DistanceRadius = 400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = SplineActor.Spline; 
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(0);
		SetActorTickEnabled(false);

		FallingFloorArray = TListedActors<ASerpentFallingFloor>().GetArray();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(Speed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;

		TArray<ASerpentFallingFloor> CheckFallingFloorArray = FallingFloorArray;

		for  (ASerpentFallingFloor Floor : FallingFloorArray)
		{
			if (GetDistanceTo(Floor) > DistanceRadius)
				continue;

			if (!Floor.IsActorTickEnabled())
			{
				Floor.ActivateFalling();
				CheckFallingFloorArray.Remove(Floor);
			}
		}

		FallingFloorArray = CheckFallingFloorArray;
	}

	UFUNCTION()
	void ActivateFallingSplineMove()
	{
		SetActorTickEnabled(true);
	} 
};