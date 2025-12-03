UCLASS(Abstract)
class ARedSpacePressurePlateIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent IndicatorEffect;
	default IndicatorEffect.bAutoActivate = false;

	FVector StartLocation;
	FVector TargetLocation;

	bool bActive = false;

	float LaunchAlpha = 0.0;
	float LaunchSpeed = 2.5;

	UFUNCTION()
	void Activate(FVector StartLoc, FVector TargetLoc)
	{
		TargetLocation = TargetLoc;
		StartLocation = StartLoc;
		SetActorLocation(StartLocation);

		LaunchAlpha = 0.0;
		IndicatorEffect.Activate(true);

		bActive = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		IndicatorEffect.Deactivate();

		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		LaunchAlpha = Math::Clamp(LaunchAlpha + LaunchSpeed * DeltaTime, 0.0, 1.0);

		FHazeRuntimeSpline RuntimeSpline;
		RuntimeSpline.AddPoint(StartLocation);

		FVector DirToTarget = (TargetLocation - StartLocation).GetSafeNormal();
		FVector MidPoint = StartLocation + (DirToTarget * StartLocation.Dist2D(TargetLocation)/2);
		MidPoint.Z = MidPoint.Z + 800.0;
		RuntimeSpline.AddPoint(MidPoint);

		RuntimeSpline.AddPoint(TargetLocation);
		RuntimeSpline.SetCustomCurvature(1.0);

		SetActorLocation(RuntimeSpline.GetLocation(LaunchAlpha));

		if (LaunchAlpha >= 1.0)
			TriggerImpact();
	}

	void TriggerImpact()
	{
		Deactivate();
	}
}