class ASoftSplitSpawnMovingDoubleObstacle : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = MeshComp_Scifi)
	UStaticMeshComponent SpinningSection;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	ASplineActor TargetSpline;

	float Speed = 150;

	UPROPERTY(EditAnywhere)
	float CurrentSplineDistance;

	UPROPERTY(EditAnywhere)
	bool bShouldHaveCustomStartPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(SplineComp == nullptr)
		SplineComp = TargetSpline.Spline;
	//	ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);

		if(!bShouldHaveCustomStartPoint)
			CurrentSplineDistance = 0;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		SpinningSection.AddLocalRotation(FRotator(0,50,0) * DeltaSeconds);

	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				DestroyActor();
			}

	}
};