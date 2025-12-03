class UBattlefieldMissileComponent : UBattlefieldAttackComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FBattlefieldMissileParams MissileParams;

	ABattlefieldMissilePoolManager PoolManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PoolManager = TListedActors<ABattlefieldMissilePoolManager>().GetSingle();
	
		// if (!bAutoBehaviour)
		SetComponentTickEnabled(false);
	}

	UFUNCTION()
	void SpawnMissile()
	{
		PoolManager.ActivateMissile(MissileParams, WorldLocation, WorldRotation, Owner);
	}
}