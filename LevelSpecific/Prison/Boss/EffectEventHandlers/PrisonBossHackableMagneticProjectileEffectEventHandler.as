UCLASS(Abstract)
class UPrisonBossHackableMagneticProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launched() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackInitialized() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hacked() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetBursted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Exploded() {}
}