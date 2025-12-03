struct FBattleFieldProjectileImpactResponseParams
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactDirection;
}

event void FOnBattlefieldProjectileImpact(FBattleFieldProjectileImpactResponseParams Params);

class UBattlefieldProjectileResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnBattlefieldProjectileImpact OnBattlefieldProjectileImpact;

	UFUNCTION()
	void TriggerProjectileImpact(FBattleFieldProjectileImpactResponseParams Params)
	{
		OnBattlefieldProjectileImpact.Broadcast(Params);
	}
}