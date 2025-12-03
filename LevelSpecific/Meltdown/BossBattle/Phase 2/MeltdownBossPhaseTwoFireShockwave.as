class AMeltdownBossPhaseTwoFireShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Shockwave;

	FHazeTimeLike ShockwaveMove;
	default ShockwaveMove.Duration = 4.0;
	default ShockwaveMove.UseLinearCurveZeroToOne();

	FVector StartScale = FVector(1,0.1,0.1);
	FVector EndScale = FVector(1,4,4);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShockwaveMove.BindUpdate(this, n"OnUpdate");
		ShockwaveMove.BindFinished(this, n"OnFinished");

		ShockwaveMove.Play();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Shockwave.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		AddActorDisable(this);
	}
};