UCLASS(Abstract)
class UBattlefieldTankTurretEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTurretStartShoot() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTurretStopShoot() {}
};