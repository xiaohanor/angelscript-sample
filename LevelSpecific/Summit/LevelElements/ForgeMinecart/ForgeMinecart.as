class AForgeMinecart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"ForgeMinecartCapability";

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;
	float CurrentDistance;
	float MoveSpeed = 800.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		ActorLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
		CurrentDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float DeltaMove = MoveSpeed * DeltaSeconds;
		float FutureDistance = CurrentDistance + DeltaMove;

		if(FutureDistance > SplineComp.SplineLength)
		{
			CurrentDistance = FutureDistance - SplineComp.SplineLength;
		}
		else
		{
			CurrentDistance += DeltaMove;
		}
		
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		ActorRotation = SplineComp.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();
	}

}