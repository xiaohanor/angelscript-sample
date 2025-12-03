class ASanctuaryLakeFallingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent PillarMesh;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent PortalSurfaceMesh;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent SplashLoc1;
	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent SplashLoc2;
	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent SplashLoc3;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterSplashVFX1;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterSplashVFX2;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterSplashVFX3;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	UPROPERTY(EditAnywhere)
	ABothPlayerTrigger BothPlayerTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timelike.BindUpdate(this, n"AnimationUpdate");
		BothPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"HandleBothPlayerTrigger");
		Timelike.BindFinished(this, n"HandleAnimationFinsihed");
	}

	UFUNCTION()
	private void HandleAnimationFinsihed()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterSplashVFX1, SplashLoc3.GetRelativeLocation());
		Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterSplashVFX2, SplashLoc2.GetRelativeLocation());
		Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterSplashVFX3, SplashLoc1.GetRelativeLocation());
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		Pivot.RelativeRotation = FRotator(0.0, 0.0,CurrentValue * 90.0);
	}

	UFUNCTION()
	private void HandleBothPlayerTrigger()
	{
		Timelike.PlayWithAcceleration(0.5);
	}
};