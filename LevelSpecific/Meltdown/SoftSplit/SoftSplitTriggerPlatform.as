class ASoftSplitTriggerPlatform : AWorldLinkDoubleActor
{
		UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	APlayerTrigger ActivateTrigger;

	float Speed = 150;
	
	float CurrentSplineDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	//	ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);
		Spline.Spline = SplineComp;
		SetActorTickEnabled(false);

		ActivateTrigger.OnActorBeginOverlap.AddUFunction(this, n"Trigger");

	}

	UFUNCTION()
	private void Trigger(AActor OverlappedActor, AActor OtherActor)
	{
		SetActorTickEnabled(true);
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