class AFinaleTimeDilationManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<AFinaleProjectileActor> DragonProjectiles; 


	float TargetDilation = 0.05;
	float CurrentTimeDilation;

	bool bActive;

	int ProjsActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentTimeDilation = Time::WorldTimeDilation;

		for (AFinaleProjectileActor Proj : DragonProjectiles)
			Proj.OnFinaleProjectileReleased.AddUFunction(this, n"OnFinaleProjectileReleased");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, TargetDilation, DeltaSeconds, 1.0);
		}
		else
		{
			CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, 1.0, DeltaSeconds, 1.0);
		}

		Time::SetWorldTimeDilation(CurrentTimeDilation);
	}

	UFUNCTION()
	void ActivateTimeDilation()
	{
		bActive = true;
	}

	UFUNCTION()
	private void OnFinaleProjectileReleased()
	{
		if (ProjsActivated >= 2)
			return;

		ProjsActivated++;
	
		if (ProjsActivated >= 2)
			bActive = false;
	}
};