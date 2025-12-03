UCLASS(Abstract)
class USanctuaryGrimbeastBoulderProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSanctuaryGrimbeastBoulderProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FSanctuaryGrimbeastBoulderProjectileOnHitEventData Data) {}
}

struct FSanctuaryGrimbeastBoulderProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryGrimbeastBoulderProjectileOnLaunchEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}

struct FSanctuaryGrimbeastBoulderProjectileOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSanctuaryGrimbeastBoulderProjectileOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}