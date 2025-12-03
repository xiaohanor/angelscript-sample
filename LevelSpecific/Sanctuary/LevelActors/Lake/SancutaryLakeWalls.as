class ASancutaryLakeWalls : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent WallMesh;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent BirdRespComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		TimeLike.SetPlayRate(1.0);
		TimeLike.BindUpdate(this, n"AnimUpdate");
		BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
	
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		TimeLike.SetPlayRate(1.0);
		TimeLike.Play();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		TimeLike.SetPlayRate(0.4);
		TimeLike.Reverse();
	}

	UFUNCTION()
	private void AnimUpdate(float CurrentValue)
	{
		Pivot.RelativeLocation = FVector(CurrentValue * 1000.0, 0.0 , 0.0);
	}
};
