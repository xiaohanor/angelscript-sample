class ADentistFlyingGummyBear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BearRoot;

	UPROPERTY(DefaultComponent, Attach = BearRoot)
	USceneComponent WingRoot1;

	UPROPERTY(DefaultComponent, Attach = BearRoot)
	USceneComponent WingRoot2;
	
	UPROPERTY()
	FRuntimeFloatCurve WingFlapFloatCurve;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	float RandomTimeOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		QueueComp.SetLooping(true);
		QueueComp.Duration(1.25, this, n"WingFlapUpdate");

		RandomTimeOffset = Math::RandRange(0.0, 3.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Pitch = Math::Sin(Time::GameTimeSeconds * 0.5 + ActorLocation.Y) * 5.0;
		float Yaw = Math::Sin(Time::GameTimeSeconds * 0.3 + ActorLocation.X) * 20.0;
		FRotator BearRelativeRotation = FRotator(Pitch, Yaw, 0.0);
		BearRoot.SetRelativeRotation(BearRelativeRotation);

		QueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime + RandomTimeOffset);
	}

	UFUNCTION()
	private void WingFlapUpdate(float Alpha)
	{
		float Roll = WingFlapFloatCurve.GetFloatValue(Alpha) * 80.0;
		WingRoot1.SetRelativeRotation(FRotator(0.0, 0.0, -Roll));
		WingRoot2.SetRelativeRotation(FRotator(0.0, 0.0, Roll));
	}
};