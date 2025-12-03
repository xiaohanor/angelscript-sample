class AJetskiBigWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent WaveDir;

	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume UnderwaterPostProcessVolume;

	FHazeTimeLike MoveWaveTimelike;

	FVector StartLoc;
	float MoveDistance = 30000.0;
	bool bDoOnce = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorScale3D = FVector(1.0, 1.0, SMALL_NUMBER);
		MoveWaveTimelike.BindUpdate(this, n"MoveWaveTimelikeUpdate");
		CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		StartLoc = ActorLocation;
	}

	UFUNCTION()
	void MoveWaveTimelikeUpdate(float Value)
	{
		SetActorLocation(Math::Lerp(StartLoc, StartLoc + (WaveDir.ForwardVector * MoveDistance), Value));
		
		FVector NewScale = FVector::OneVector;
		NewScale.Z = Math::Lerp(0.0, 1.0, Value);
		SetActorScale3D(NewScale);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (Cast<AJetski>(OtherActor) == nullptr)
			return;

		if (bDoOnce)
			return;

		bDoOnce = true;
		UnderwaterPostProcessVolume.BlendWeight = 1.0;

		TListedActors<AJetskiBreakingWindow> ListedActors;
		for (AJetskiBreakingWindow Window : ListedActors)
			Window.DeactivateEffects();
	}

	UFUNCTION()
	void StartMovingWave()
	{
		MoveWaveTimelike.PlayFromStart();
	}
}