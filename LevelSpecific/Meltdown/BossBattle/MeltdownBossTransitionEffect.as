class AMeltdownBossTransitionEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume GlitchPostProcess;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike SphereMoveIn;
	default SphereMoveIn.Duration = 1.95;
	default SphereMoveIn.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike SphereMoveOut;
	default SphereMoveOut.Duration = 1.75;
	default SphereMoveOut.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	AScenepointActor NextWorldTarget;

	UPROPERTY()
	float StartSize = 60000;
	UPROPERTY()
	float ShrinkSize = 1000;
	UPROPERTY()
	float FinalSize = 60000;


	UFUNCTION(BlueprintCallable)
	void WorldTransition()
	{
		StartWorldTransition();
	}

	UFUNCTION(BlueprintEvent)
	void StartWorldTransition()
	{

	}

};