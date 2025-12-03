UCLASS(Abstract)
class UMeltdownBossPhaseTwoAsteroidEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnAsteroid() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByBat() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByGlitch(FMeltdownGlitchImpact Impact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyedByPlayerHit() {}
};