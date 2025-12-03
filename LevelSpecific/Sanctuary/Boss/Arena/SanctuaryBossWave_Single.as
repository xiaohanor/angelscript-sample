UCLASS(Abstract)
class ASanctuaryBossWave_Single : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaveRoot;

	UPROPERTY(DefaultComponent, Attach = WaveRoot)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY()
	FHazeTimeLike WaveScaleTimeLike;
	default WaveScaleTimeLike.UseSmoothCurveZeroToOne();
	default WaveScaleTimeLike.Duration = 3.0;

	UPROPERTY()
	float WaveSpeed = 1000.0;

	UPROPERTY()
	float WaveDistance = 15000.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		WaveScaleTimeLike.BindUpdate(this, n"WaveScaleTimeLikeUpdate");
		WaveScaleTimeLike.BindFinished(this, n"WaveScaleTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WaveRoot.AddRelativeLocation(FVector::ForwardVector * WaveSpeed * DeltaSeconds);
		
		if (WaveRoot.RelativeLocation.X > WaveDistance && !WaveScaleTimeLike.IsReversed())
			WaveScaleTimeLike.Reverse();
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		WaveRoot.SetRelativeLocation(FVector::ZeroVector);
		WaveScaleTimeLike.Play();
		bActive = true;
	}

	UFUNCTION()
	private void WaveScaleTimeLikeUpdate(float CurrentValue)
	{
		WaveRoot.SetRelativeScale3D(FVector(1.0, 1.0, CurrentValue));
	}

	UFUNCTION()
	private void WaveScaleTimeLikeFinished()
	{
		if (WaveScaleTimeLike.IsReversed())
		{
			bActive = false;
			AddActorDisable(this);
		}
	}
};
