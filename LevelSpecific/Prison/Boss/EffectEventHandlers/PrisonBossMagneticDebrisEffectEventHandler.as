UCLASS(Abstract)
class UPrisonBossMagneticDebrisEffectEventHandler : UHazeEffectEventHandler
{
	//Generic
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetBursted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() {}

	//Boss controlled
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabbedByBoss() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchedByBoss() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeflectedByBoss() {}

	//Player controlled
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabbedByPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchedByPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeflectedByPlayer() {}
}