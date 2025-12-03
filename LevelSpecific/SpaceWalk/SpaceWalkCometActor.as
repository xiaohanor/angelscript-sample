class ASpaceWalkCometActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Comet;

	UPROPERTY()
	UHazeSplineComponent SplineComp;
	
	UPROPERTY()
	float Speed = 150;

	float CurrentSplineDistance;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentSplineDistance += Speed * DeltaSeconds;

		Comet.AddLocalRotation(FRotator(1,3,4) * DeltaSeconds);

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				USpaceWalkDebrisEffectHandler::Trigger_Explode(this);
				DestroyActor();
			}

	}
};