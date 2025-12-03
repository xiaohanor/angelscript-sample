struct FGravityBikeMissileLauncherProjectileImpactEventData
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;
};

struct FGravityBikeMissileLauncherProjectilePhaseActivatedEventData
{
	UPROPERTY()
	int PhaseIndex;
};

UCLASS(Abstract)
class UGravityBikeMissileLauncherProjectileEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeMissileLauncherProjectile MissileLauncherProjectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MissileLauncherProjectile = Cast<AGravityBikeMissileLauncherProjectile>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FGravityBikeMissileLauncherProjectileImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPhaseActivated(FGravityBikeMissileLauncherProjectilePhaseActivatedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnSpawn() {}
};