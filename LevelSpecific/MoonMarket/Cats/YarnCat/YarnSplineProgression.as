class AYarnSplineProgression : APropLineProgression
{
	UPROPERTY(EditInstanceOnly)
	AActor YarnCat;

	default bInverted = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		check(Target.bGameplaySpline, f"{Target.Name} is not marked as gameplay spline");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);
		auto Spline = Spline::GetGameplaySpline(Target, this);
		
		if(Spline != nullptr)
			Progression = Spline.GetClosestSplineDistanceToWorldLocation(YarnCat.ActorLocation) / Spline.SplineLength;

		PrintToScreen(f"{Progression=}");
	}
};