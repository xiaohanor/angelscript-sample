class AShuttleLiftEnergyPendulum : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EmissiveBlock;

	float Amount = 190.0;
	private float Progress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Progress = Math::Sin(Time::GameTimeSeconds * 3.5);
		float TargetOffset = Progress * Amount;
		EmissiveBlock.RelativeLocation = FVector(0, TargetOffset, 0);
		Progress += 1;
		Progress /= 2;
	}

	void StartPendulum()
	{
		SetActorTickEnabled(true);
	}

	bool HasSafeProgress()
	{
		return Progress > 0.375 && Progress < 0.625;
	}
};