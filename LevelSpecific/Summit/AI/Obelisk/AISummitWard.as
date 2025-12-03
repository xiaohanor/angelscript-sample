event void FOnObeliskWardKilled(AHazeActor Ward);

class AAISummitWard : AHazeActor
{
	FOnObeliskWardKilled OnObeliskWardKilled;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionObjectType(ECollisionChannel::EnemyCharacter);

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UCapsuleComponent CapsuleComp;
	// default CapsuleComp.SetCollisionObjectType(ECollisionChannel::EnemyCharacter);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIDeathCapability");
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"DealAcidDamage");
		TailResponseComp.OnHitByTailAttack.AddUFunction(this, n"DealTailDamage");
	}

	UFUNCTION()
	void DealAcidDamage(FAcidHit Params)
	{
		HealthComp.TakeDamage(0.15, EDamageType::Acid, Params.PlayerInstigator);
		float CurHealth = HealthComp.GetCurrentHealth();
	}

	UFUNCTION()
	void DealTailDamage(FTailAttackParams Params)
	{
		HealthComp.TakeDamage(0.4, EDamageType::Impact, Params.PlayerInstigator);
	}

	UFUNCTION()
	void OnDie(AHazeActor ActorDying)
	{
		OnObeliskWardKilled.Broadcast(this);
		FSummitWardDeathParams Params;
		Params.Location = ActorCenterLocation;
		Params.Rotation = ActorRotation;
		UAISummitWardEffectsHandler::Trigger_DestroyWard(this, Params);
		DestroyActor();
	}
}