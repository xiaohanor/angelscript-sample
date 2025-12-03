class AMeltdownBossPhaseThreeCrackFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent IceMesh;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayTrigger;

	FHazeTimeLike CrackFloor;
	default CrackFloor.Duration = 2.0;
	default CrackFloor.UseLinearCurveOneToZero();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnOverlap");
		CrackFloor.BindUpdate(this, n"UpdateCrack");
		CrackFloor.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	private void OnFinished()
	{
		IceMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void UpdateCrack(float CurrentValue)
	{
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Display Frame", CurrentValue);
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Global Piece Scale Multiplier", CurrentValue);
	}

	UFUNCTION()
	private void OnOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;
		
		CrackFloor.Play();
	}
};