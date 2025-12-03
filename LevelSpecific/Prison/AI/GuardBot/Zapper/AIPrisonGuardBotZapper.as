UCLASS(Abstract)
class AAIPrisonGuardBotZapper : AAIPrisonGuardBot
{
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardBotZapperBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardBotRemoteHackableShootCapability");

	UPROPERTY(DefaultComponent)
	UPrisonGuardBotZapperMuzzleComponent ZapperComp;
	
	UPROPERTY(DefaultComponent)
	UPrisonGuardBotZapperAutoAimTargetComponent ZapperAutoAimComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	FText ZapTutorialText;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> PlayerDeathEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> PlayerDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	FAimingSettings AimSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonGuardBotZapperProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	bool bShowTutorial = true;

	FVector ShootingTargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SetActorControlSide(Game::Mio);		
		TargetingComponent.Target = Game::Mio;
		RespawnComp.OnPostRespawn.AddUFunction(this, n"Respawn");

		ZapperComp.AttachToComponent(Mesh, n"MuzzleEffect");
	}

	UFUNCTION()
	private void Respawn()
	{
		TargetingComponent.Target = Game::Mio;
	}

	UFUNCTION(BlueprintPure)
	TArray<AAIPrisonGuardBotZapper> GetAllZappers()
	{
		TListedActors<AAIPrisonGuardBotZapper> Zappers;
		return Zappers.GetArray();
	}

	UFUNCTION()
	void ResetHealthBar()
	{
		HealthComp.Reset();
		HealthBarComp.SnapBarToHealth();
		HealthBarComp.UpdateHealthBarVisibility();
	}
}