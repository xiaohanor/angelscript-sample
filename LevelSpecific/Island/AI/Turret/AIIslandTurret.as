UCLASS(Abstract)
class AAIIslandTurret : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTurretBehaviourCompoundCapability");

	UPROPERTY(EditAnywhere)
	bool bUseShield;

	UPROPERTY(EditAnywhere)
	bool bIsHackable;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USceneComponent HackSceneComp;

	UPROPERTY(DefaultComponent, Attach = "HackSceneComp")
	UStaticMeshComponent PanelMesh;

	UPROPERTY(DefaultComponent, Attach = "HackSceneComp")
	UStaticMeshComponent HackedPanelMesh;

	UPROPERTY(DefaultComponent)
	UIslandTurretHackComponent HackComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterField ShieldComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunDamageableComponent CopsGunsDamageComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterFieldTargetableComponent ShieldBusterFieldTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterImpactResponseComponent ShieldBusterImpactComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunShootTargetableComponent CopsGunsShootTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandPushKnockSelfImpactResponseComponent KnockSelfImpactComp;

	UPROPERTY(DefaultComponent)
	UIslandPushKnockTargetImpactResponseComponent KnockTargetImpactComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	UBasicAIProjectileLauncherComponent Weapon;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(!bUseShield)
		{
			ShieldComp.DisableField(this);
		}

		HackComp.bEnabled = bIsHackable;		
		if(!bIsHackable)
		{
			HackSceneComp.SetVisibility(false, true);
		}
		else
		{			
			HackedPanelMesh.SetVisibility(false, true);
			HackComp.OnHacked.AddUFunction(this, n"OnHacked");
			HackComp.OnSecured.AddUFunction(this, n"OnSecured");
		}

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		if(bUseShield)
			ShieldComp.Reset();
		if(bIsHackable)
			HackComp.Secure();
	}

	UFUNCTION()
	private void OnSecured()
	{
		PanelMesh.SetVisibility(true, true);
		HackedPanelMesh.SetVisibility(false, true);
	}

	UFUNCTION()
	private void OnHacked()
	{
		PanelMesh.SetVisibility(false, true);
		HackedPanelMesh.SetVisibility(true, true);
	}
}