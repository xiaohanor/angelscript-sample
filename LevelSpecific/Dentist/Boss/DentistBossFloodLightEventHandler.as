UCLASS(Abstract)
class UDentistBossFloodLightEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFloodLightActivated() {}
};