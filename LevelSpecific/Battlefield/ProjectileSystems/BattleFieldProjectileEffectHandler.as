struct FOnBattleFieldOnProjectileFiredParams
{
	UPROPERTY()
	FVector Location;
	UPROPERTY()
	FRotator Rotation;
	UPROPERTY()
	EBattlefieldProjectileType Type;
}

struct FOnBattleFieldOnProjectileImpactParams
{
	UPROPERTY()
	FVector Location;
	UPROPERTY()
	FVector Normal;
}

UCLASS(Abstract)
class UBattleFieldProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileFired(FOnBattleFieldOnProjectileFiredParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileImpact(FOnBattleFieldOnProjectileImpactParams Params) {}
}
