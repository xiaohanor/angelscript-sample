UCLASS(Abstract)
class AAISummitStoneBeastZapper : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastZapperCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIClimbAlongSplineMovementCapability"); 

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;
	
	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	USpotLightComponent TelegraphChargeSpotLight;
	default TelegraphChargeSpotLight.SetVisibility(false);

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	USpotLightComponent VulnerableSpotLight;
	default VulnerableSpotLight.SetVisibility(false);

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	USceneComponent TelegraphChargeVFXLocation;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatTargetComponent TargetComp;
	
	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	UNiagaraComponent VFXShieldTemp;
	default VFXShieldTemp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UDecalComponent BeamAttackDecalComp;
	default BeamAttackDecalComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASummitStoneBeastZapperLightningCrystalActor> LightningCrystalClass;

	UHazeActorNetworkedSpawnPoolComponent LightningCrystalSpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GetOrCreateGroundLightningCrystalSpawnPool();

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);	
		
		HealthComp.OnDie.AddUFunction(this, n"OnZapperDie");
		SwordResponseComp.OnHit.AddUFunction(this, n"OnSwordHit");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		VFXShieldTemp.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void OnZapperDie(AHazeActor ActorBeingKilled)
	{
		USummitStoneBeastZapperEffectHandler::Trigger_OnDeath(this);
		MovementComponent.Reset();
	}

	UHazeActorNetworkedSpawnPoolComponent GetOrCreateGroundLightningCrystalSpawnPool()
	{
		check(LightningCrystalClass != nullptr);
		if (LightningCrystalClass != nullptr)
		{
			LightningCrystalSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(LightningCrystalClass, this);
		}
		return LightningCrystalSpawnPool;
	}
	
	private float DamageCooldownTimer = 0.0;
	UFUNCTION()
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		if (!VFXShieldTemp.IsHiddenInGame())
		{
			// Deal player damage?
			USummitStoneBeastZapperEffectHandler::Trigger_OnDeflectedHit(this);
		}
		else
		{
			// Take damage
			if (DamageCooldownTimer > 0.0)
				return;
			
			USummitStoneBeastZapperEffectHandler::Trigger_OnDamage(this);
			HealthComp.TakeDamage(0.5, EDamageType::MeleeSharp, Cast<AHazeActor>(CombatComp.Owner));
			DamageCooldownTimer = 0.25;

			// TODO: set hit direction
			AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::HitReaction, EBasicBehaviourPriority::Minimum, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DamageCooldownTimer -= DeltaSeconds;
	}
}