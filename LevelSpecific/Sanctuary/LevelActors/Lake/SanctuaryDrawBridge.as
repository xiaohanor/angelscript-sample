class ASanctuaryDrawBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent Bridge;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent BirdRespComp;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalTargetComponent TargetCompRight;
	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalTargetComponent TargetCompLeft;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetCompRight.MaximumDistance = 3000;
		TargetCompRight.DisableForPlayer(Game::Zoe, this);
		TargetCompLeft.MaximumDistance = 3000;
		TargetCompLeft.DisableForPlayer(Game::Zoe, this);
		TimeLike.BindUpdate(this, n"AnimUpdate");
		BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		TargetCompRight.EnableForPlayer(Game::Zoe, this);
		TargetCompLeft.EnableForPlayer(Game::Zoe, this);
		TimeLike.Play();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		TimeLike.Reverse();
		TargetCompRight.DisableForPlayer(Game::Zoe, this);
		TargetCompLeft.DisableForPlayer(Game::Zoe, this);
	}

	UFUNCTION()
	private void AnimUpdate(float CurrentValue)
	{
		Pivot.RelativeRotation = FRotator(0.0, 0.0,CurrentValue * -60.0);
	}
};