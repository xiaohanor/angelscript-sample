UCLASS(Abstract)
class USummitEggBeastProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileImpact() {}
};