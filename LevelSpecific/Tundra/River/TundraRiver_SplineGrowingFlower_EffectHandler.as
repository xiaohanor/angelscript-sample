UCLASS(Abstract)
class UTundraRiver_SplineGrowingFlower_EffectHandler : UHazeEffectEventHandler
{
	ATundraRiver_SplineGrowingFlower GrowingFlower;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrowingFlower = Cast<ATundraRiver_SplineGrowingFlower>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintPure)
	float GetCurrentAlpha()
	{
		return GrowingFlower.CurrentAlpha;
	}

	UFUNCTION(BlueprintPure)
	float GetLowestAlpha()
	{
		return GrowingFlower.LowestSplineDistance / GrowingFlower.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	bool IsAtTheBottom()
	{
		return (GetCurrentAlpha()-0.001) <= GetLowestAlpha();
	}
}