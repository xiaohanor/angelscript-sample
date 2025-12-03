class AMeltdownBossPhaseThreeSwingingCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Crane;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TargetCrane;
	default TargetCrane.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default TargetCrane.SetHiddenInGame(true);

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	FHazeTimeLike MoveCrane;
	default MoveCrane.Duration = 2.0;
	default MoveCrane.UseSmoothCurveZeroToOne();

	FRotator StartRot;
	FRotator EndRot;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"OnOverlap");
		MoveCrane.BindUpdate(this, n"UpdateCrane");

		StartRot = Crane.RelativeRotation;
		EndRot = TargetCrane.RelativeRotation;
	}

	UFUNCTION()
	private void UpdateCrane(float CurrentValue)
	{
		Crane.SetRelativeRotation(Math::LerpShortestPath(StartRot, EndRot, CurrentValue));
		
	}

	UFUNCTION()
	private void OnOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazeCharacter Player = Cast<AHazeCharacter>(OtherActor);

		if (Player != nullptr)
			MoveCrane.Play();
			
	}
};