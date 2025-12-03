class UBrazierSplineCompononent : UActorComponent
{
//	UPROPERTY(EditAnywhere)
//	ASplineActor Spline;

	float SplineSpeed = 1200.0;

	float CurrentDistance;

	bool bGoForward;

//	UHazeSplineComponent SplineComp;

	UTeenDragonTailClimbableComponent DragonClimb;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	SplineComp = Spline.Spline;

		DragonClimb = UTeenDragonTailClimbableComponent::Get(Owner);

		DragonClimb.OnTailClimbStarted.AddUFunction(this, n"OntailStarted");

		DragonClimb.OnTailClimbStopped.AddUFunction(this, n"OntailStopped");
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	/*	if(bGoForward)	
			CurrentDistance += SplineSpeed * DeltaSeconds;
		else
			CurrentDistance -= SplineSpeed * DeltaSeconds;

		CurrentDistance = Math::Clamp(CurrentDistance, 0, SplineComp.SplineLength);

		GetOwner().ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
	*/
	}

	UFUNCTION()
	private void OntailStarted(FTeenDragonTailClimbParams Params)
	{
		bGoForward = true;

	}
	UFUNCTION()
	private void OntailStopped(FTeenDragonTailClimbParams Params)
	{
		bGoForward = false;
	}

}