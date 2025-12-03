class ASanctuaryRotatingPillar : AHazeActor
{
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent Pillar;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent BirdRespComp;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalTargetComponent TargetComp;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetComp.MaximumDistance = 3000;
		
	
		TimeLike.BindUpdate(this, n"AnimUpdate");
		BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		TimeLike.PlayWithAcceleration(0.5);
		
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		TimeLike.StopWithDeceleration(0.5);
	
	}

	UFUNCTION()
	private void AnimUpdate(float CurrentValue)
	{
		Pivot.RelativeRotation = FRotator(0.0,CurrentValue * 360.0, 0.0);
	}
};