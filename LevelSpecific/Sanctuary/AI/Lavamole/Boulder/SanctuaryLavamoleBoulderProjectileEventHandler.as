UCLASS(Abstract)
class USanctuaryLavamoleBoulderProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSanctuaryLavamoleBoulderProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FSanctuaryLavamoleBoulderProjectileOnHitEventData Data) {}
}

struct FSanctuaryLavamoleBoulderProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryLavamoleBoulderProjectileOnLaunchEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}

struct FSanctuaryLavamoleBoulderProjectileOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSanctuaryLavamoleBoulderProjectileOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}