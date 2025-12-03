class ASanctuaryBossSkydiveBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BeamRoot;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UStaticMeshComponent BeamMesh;

	UPROPERTY()
	FHazeTimeLike GrowTimeLike;
	default GrowTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float BigWaitDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float SmallWaitDuration = 4.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		GrowTimeLike.BindUpdate(this, n"GrowTimeLikeUpdate");
		GrowTimeLike.BindFinished(this, n"GrowTimeLikeFinished");
	
		

		if (StartDelay == 0.0)
			GrowTimeLike.PlayFromStart();
		else
			Timer::SetTimer(this, n"PlayGrowTimeLike", StartDelay);
	}

	UFUNCTION()
	private void PlayGrowTimeLike()
	{
		GrowTimeLike.PlayFromStart();
	}

	


	UFUNCTION()
	private void GrowTimeLikeFinished()
	{
		Timer::SetTimer(this, n"PlayShrinkTimeLike", BigWaitDuration);
	}

	UFUNCTION()
	private void PlayShrinkTimeLike()
	{
		GrowTimeLike.Reverse();
		
		Timer::SetTimer(this, n"PlayGrowTimeLike", SmallWaitDuration);
	}

	UFUNCTION()
	private void GrowTimeLikeUpdate(float CurrentValue)
	{
		BeamRoot.SetRelativeScale3D(FVector(1, 1, CurrentValue * 300));
	}
};