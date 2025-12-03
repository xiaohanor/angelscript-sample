event void FOnCubeDone();

class AMeltdownPhaseTwoBigCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BigCube;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BigCubeTarget;
	default BigCubeTarget.SetHiddenInGame(true);
	default BigCubeTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = BigCube)
	USceneComponent MissileSpawnPoint;

	FOnCubeDone CubeIsDone;

	FHazeTimeLike CubeLand;
	default CubeLand.Duration = 1.0;
	default CubeLand.UseLinearCurveZeroToOne();

	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = BigCube.RelativeLocation;
		TargetLocation = BigCubeTarget.RelativeLocation;

		CubeLand.BindUpdate(this, n"OnUpdated");
		CubeLand.BindFinished(this, n"OnFinished");
	}

	UFUNCTION(BlueprintCallable)
	void LaunchCube()
	{
		CubeLand.Play();
	}

	UFUNCTION()
	private void OnUpdated(float CurrentValue)
	{
		BigCube.SetRelativeLocation(Math::Lerp(StartLocation,TargetLocation, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		Finished();
		CubeIsDone.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void Finished()
	{

	}
};