class ABattlefieldAlienGunner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBattlefieldProjectileComponent ProjComp1;
	default ProjComp1.bAutoBehaviour = false;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBattlefieldProjectileComponent ProjComp2;
	default ProjComp2.bAutoBehaviour = false;
	default ProjComp2.DelayFire = 0.1;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BattlefieldAlienGunnerFireCapability");

	bool bGunnerActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		// ActivateGunner();
	}

	UFUNCTION()
	void ActivateGunner()
	{
		bGunnerActive = true;
	}
}