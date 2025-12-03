class ASpaceWalkDebrisSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshComp;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float Speed = 300;

	float CurrentSplineDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				DestroyActor();
			}

	}
};