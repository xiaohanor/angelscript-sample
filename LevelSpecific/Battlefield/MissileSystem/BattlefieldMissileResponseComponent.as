struct FBattleFieldMissileImpactResponseParams
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactDirection;
}

event void FOnBattlefieldMissileImpact(FBattleFieldMissileImpactResponseParams Params);

class UBattlefieldMissileResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnBattlefieldMissileImpact OnBattlefieldMissileImpact;

	UFUNCTION()
	void TriggerMissileImpact(FBattleFieldMissileImpactResponseParams Params)
	{
		OnBattlefieldMissileImpact.Broadcast(Params);
	}
}