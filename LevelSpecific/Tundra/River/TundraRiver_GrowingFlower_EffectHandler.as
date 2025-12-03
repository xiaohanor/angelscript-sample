UCLASS(Abstract)
class UTundraRiver_GrowingFlower_EffectHandler : UHazeEffectEventHandler
{
	ATundraRiver_GrowingFlower GrowingFlower;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrowingFlower = Cast<ATundraRiver_GrowingFlower>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving()
	{
	}

	UFUNCTION(BlueprintPure)
	float GetHeightAlpha() property
	{
		return (GrowingFlower.SyncedCurrentHeight.Value + GrowingFlower.GroundPoundOffset)/GrowingFlower.MaxHeight;
	}
};