UFUNCTION(BlueprintCallable, Category = "Camera")
mixin void ApplyCameraLookTowardsSpline(AHazePlayerCharacter Player, UHazeSplineComponent SplineComp, FCameraLookTowardsSplineSettings Settings, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if(!ensure(Player != nullptr))
		return;

	if(!ensure(SplineComp != nullptr))
		return;

	auto Component = UCameraLookTowardsSplineComponent::GetOrCreate(Player);

	FCameraLookTowardsSplineData SplineData;
	SplineData.Spline = SplineComp;
	SplineData.Settings = Settings;
	Component.Apply(SplineData, Instigator, Priority);
}

UFUNCTION(BlueprintCallable, Category = "Camera")
mixin void ClearCameraLookTowardsSpline(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto Component = UCameraLookTowardsSplineComponent::Get(Player);
	if(Component == nullptr)
		return;

	Component.Clear(Instigator);
}