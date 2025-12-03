class AMoonGuardianCatZees : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ZRoot;

	UPROPERTY()
	FRuntimeFloatCurve ScaleCurve;
	default ScaleCurve.AddDefaultKey(0, 0.1);
	default ScaleCurve.AddDefaultKey(0.5, 1.0);
	default ScaleCurve.AddDefaultKey(1.0, 0.1);

	float TotalTime = 2.0;
	float TimeRun = 0.0;
	float UpSpeed = 350.0;
	float RightDistance = 50.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorScale3D(FVector(ScaleCurve.GetFloatValue(0.0)));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeRun += DeltaSeconds;

		float RightOffsetMultiplier = Math::Sin(TimeRun * 4.0);
		float TimeAlpha = Math::Saturate(TimeRun / TotalTime);
		float ScaleOverTime = ScaleCurve.GetFloatValue(TimeAlpha);
		
		SetActorScale3D(FVector(ScaleOverTime));

		ActorLocation += FVector::UpVector * UpSpeed * DeltaSeconds;
		ZRoot.RelativeLocation = FVector(0.0 ,RightOffsetMultiplier * RightDistance, 0.0);

		if (TimeRun > TotalTime)
		{
			DestroyActor();
		}
	}
};