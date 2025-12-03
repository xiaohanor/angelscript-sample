UCLASS(Abstract)
class USanctuaryLavamoleMortarProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSanctuaryLavamoleMortarProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

struct FSanctuaryLavamoleMortarProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryLavamoleMortarProjectileOnLaunchEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}