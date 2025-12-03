UCLASS(Abstract)
class USanctuaryLavaMomBoulderProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSanctuaryLavaMomBoulderProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FSanctuaryLavaMomBoulderProjectileOnHitEventData Data) {}
}

struct FSanctuaryLavaMomBoulderProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryLavaMomBoulderProjectileOnLaunchEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}

struct FSanctuaryLavaMomBoulderProjectileOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSanctuaryLavaMomBoulderProjectileOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}