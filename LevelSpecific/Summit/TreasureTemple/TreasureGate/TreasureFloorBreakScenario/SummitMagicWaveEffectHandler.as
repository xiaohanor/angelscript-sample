UCLASS(Abstract)
class USummitMagicWaveEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagicWaveDespawned() {}
};