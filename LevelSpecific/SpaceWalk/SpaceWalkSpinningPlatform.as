class ASpaceWalkSpinningPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TargetPlatform;
	default TargetPlatform.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default TargetPlatform.SetHiddenInGame(true);

	UPROPERTY()
	FHazeTimeLike MovePlatform;
	default MovePlatform.Duration = 1.0;
	default MovePlatform.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatform.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Platform.SetRelativeLocation(Math::Lerp(Platform.RelativeLocation, TargetPlatform.RelativeLocation, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.AddLocalRotation(FRotator(0,10,0) * DeltaSeconds);
	}

};