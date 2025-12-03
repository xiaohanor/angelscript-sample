struct FCoastBossPowerUpPickupEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ACoastBossPlayerNormalPowerUp PowerUp;
}

UCLASS(Abstract)
class UCoastBossPowerUpEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickup(FCoastBossPowerUpPickupEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn(FCoastBossPowerUpPickupEffectParams Params) {}
}