event void FonFinished();

class AFreakySpaceAsteroid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Asteroid;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AsteroidTarget;

	UPROPERTY()
	FTransform StartAsteroid;

	UPROPERTY()
	FTransform TargetAsteroid;

	UPROPERTY()
	FonFinished Finished;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartAsteroid = Asteroid.RelativeTransform;

		TargetAsteroid = AsteroidTarget.RelativeTransform;
	}
	
	UFUNCTION(BlueprintCallable)
	void BP_OnFinished()
	{
		Finished.Broadcast();
	}

}