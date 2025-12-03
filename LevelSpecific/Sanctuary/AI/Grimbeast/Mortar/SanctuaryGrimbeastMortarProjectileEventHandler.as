UCLASS(Abstract)
class USanctuaryGrimbeastMortarProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSanctuaryGrimbeastMortarProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

struct FSanctuaryGrimbeastMortarProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryGrimbeastMortarProjectileOnLaunchEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}