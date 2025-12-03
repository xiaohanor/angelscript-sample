class AJetskiCorridorWater : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume UnderwaterPostProcessVolume;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	float Speed = 170.0;
	
	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
	}
	
	UFUNCTION()
	void StartMovingWater()
	{
		SetActorTickEnabled(true);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector(0.0, 0.0, Speed * DeltaSeconds));

		if (ActorLocation.Z - StartLoc.Z > 1800.0)
		{
			SetActorTickEnabled(false);

			TArray<AActor>  AttachedActors;
			GetAttachedActors(AttachedActors);

			for(auto Actor : AttachedActors)
				Actor.SetActorHiddenInGame(true);
			
			SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void SpeedUpWater()
	{
		TListedActors<AJetskiBreakingWindow> ListedActors;
		for (AJetskiBreakingWindow Window : ListedActors)
			Window.DeactivateEffects();

		// TListedActors<AJetski> Jetskis;
		// for (AJetski Jetski : Jetskis)
		// 	Jetski.EnterUnderwaterSplineFollowMode();	
	}
}