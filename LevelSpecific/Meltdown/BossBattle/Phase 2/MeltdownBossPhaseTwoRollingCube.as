class AMeltdownBossPhaseTwoRollingCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Cube;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TargetCube;
	default TargetCube.SetHiddenInGame(true);
	default TargetCube.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	FHazeTimeLike CubeMove;
	default CubeMove.Duration = 3.0;
	default CubeMove.UseLinearCurveZeroToOne();

	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = Cube.WorldLocation;
		TargetLocation = TargetCube.WorldLocation;

		CubeMove.BindUpdate(this, n"OnUpdate");
		CubeMove.BindFinished(this, n"OnFinished");

		CubeMove.Play();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Cube.SetWorldLocation(Math::Lerp(StartLocation,TargetLocation,CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Cube.AddLocalRotation(FRotator(3,0,0));
	}
};