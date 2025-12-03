class ACrystalGrowthScaling : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCrystalGrowthKillComponent KillComp;

	UPROPERTY(EditAnywhere)
	float Speed = 1.0;

	UPROPERTY(EditAnywhere)
	float SpeedOffset = 0.0;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = MeshRoot.RelativeScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ScaleMultiplier = 0.2 + (Math::Sin(SpeedOffset + Time::GameTimeSeconds * Speed) + 1) / 2.2;
		MeshRoot.SetRelativeScale3D(StartScale * ScaleMultiplier);
	}
};