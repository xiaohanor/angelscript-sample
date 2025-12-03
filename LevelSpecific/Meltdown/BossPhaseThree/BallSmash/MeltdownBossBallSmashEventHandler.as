UCLASS(Abstract)
class UMeltdownBossBallSmashEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Smash()
	{
	}
}