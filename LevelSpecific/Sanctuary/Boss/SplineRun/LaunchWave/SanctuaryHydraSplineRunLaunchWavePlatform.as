class ASanctuaryHydraSplineRunLaunchWavePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaveFloatRoot;

	UPROPERTY()
	FRuntimeFloatCurve WaveCurve;

	ASanctuaryHydraSplineRunLaunchWave LaunchWave;

	FHazeAcceleratedTransform AccTransform;
	FTransform TargetTransform;

	float MinValue = 330.0;
	float MaxValue = 460.0;
	float Height = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchWave = Cast<ASanctuaryHydraSplineRunLaunchWave>(AttachParentActor);

		if (!DevToggleHydraPrototype::SplineRunLaunchWave.IsEnabled())
			AddActorDisable(this);

		DevToggleHydraPrototype::SplineRunLaunchWave.BindOnChanged(this, n"HandleDevToggled");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!LaunchWave.bWaveActive)
			return;

		if (LaunchWave.XYScale == 0.0)
			return;

		float DistanceToCenter = GetHorizontalDistanceTo(LaunchWave);

		float Alpha = (Math::Clamp(DistanceToCenter, LaunchWave.XYScale * MinValue, LaunchWave.XYScale * MaxValue) / LaunchWave.XYScale - MinValue) / (MaxValue - MinValue);

		SetPlatformLocationAndRotation(Alpha);

		AccTransform.SpringTo(TargetTransform, 20.0, 0.5, DeltaSeconds);
		WaveFloatRoot.SetRelativeLocationAndRotation(AccTransform.Value.Location, AccTransform.Value.Rotation);
	}

	UFUNCTION()
	private void SetPlatformLocationAndRotation(float Value)
	{
		float CurrentValue = WaveCurve.GetFloatValue(Value);

		TargetTransform.SetLocation(FVector::UpVector * CurrentValue * LaunchWave.ZScale * Height);

		float SmallerValue = WaveCurve.GetFloatValue(Math::Clamp(Value -0.01, 0.0, 1.0));
		float BiggerValue = WaveCurve.GetFloatValue(Math::Clamp(Value +0.01, 0.0, 1.0));

		FVector Direction = FVector(0.02, 0.0, SmallerValue - BiggerValue).GetSafeNormal();

		if (Value != 0.0 && Value != 1.0)
			TargetTransform.SetRotation(Direction.Rotation());

		else
			TargetTransform.SetRotation(FRotator::ZeroRotator);
	}

	UFUNCTION()
	private void HandleDevToggled(bool bNewState)
	{
		if (bNewState)
			RemoveActorDisable(this);
		else
			AddActorDisable(this);
	}
};