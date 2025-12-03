class AMeltdownGlitchShootingOrbEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Orb;

	UPROPERTY(EditAnywhere)
	AMeltdownGlitchShootingPickup Pickup;

	FVector StartScale;

	UPROPERTY(EditAnywhere)
	FVector EndScale;

	FHazeTimeLike OrbLike;
	default OrbLike.Duration = 4;
	default OrbLike.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

        SetActorHiddenInGame(true);
		
		StartScale = Orb.RelativeScale3D;

		OrbLike.BindUpdate(this, n"OnUpdate");
		OrbLike.BindFinished(this, n"OnFinished");
	}

	UFUNCTION(BlueprintCallable)
	void OnGlitchActivation()
	{
		OrbLike.PlayFromStart();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Orb.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		AddActorDisable(this);
	}
};