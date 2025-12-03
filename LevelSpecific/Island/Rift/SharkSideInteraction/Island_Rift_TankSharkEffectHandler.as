UCLASS(Abstract)
class UIsland_Rift_TankSharkEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkHitTheGlass() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkStart() {}
};