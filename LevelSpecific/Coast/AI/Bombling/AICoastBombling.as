UCLASS(Abstract)
class AAICoastBombling : ABasicAIGroundMovementCharacter
{
	// default MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;

	default CapsuleComponent.bGenerateOverlapEvents = true; // TODO: Remove!

	default CapabilityComp.DefaultCapabilities.Add(n"CoastBomblingBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIGroundMovementCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"CoastBomblingMovementCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"CoastBomblingSplineMovementCapability");

	UPROPERTY(DefaultComponent)
	UCoastBomblingDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UCoastBomblingExplosionComp ExplosionComp;

	UCoastBomblingSettings ExploderSettings;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UStaticMeshComponent BallMesh;
	float DeployedDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ExploderSettings = UCoastBomblingSettings::GetSettings(this);

		HealthComp.OnDie.AddUFunction(this, n"OnExploderDie");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnExploderTakeDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		BallMesh = Cast<UStaticMeshComponent>(Mesh.GetChildComponentByClass(UStaticMeshComponent));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReset()
	{
		UCoastBomblingEffectHandler::Trigger_OnRespawn(this);
		AutoAimTargetComp.Enable(this);
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	private void OnExploderDie(AHazeActor ActorBeingKilled)
	{
		AActor AttachActor = nullptr;

		if(RespawnComp.Spawner != nullptr)
			AttachActor = RespawnComp.Spawner.AttachParentActor;

		if(AttachActor == nullptr)
			AttachActor = this;

		auto Data = FCoastBomblingEffectOnDeathData(AttachActor);
		Data.DeathDuration = ExploderSettings.DeathDuration;
		UCoastBomblingEffectHandler::Trigger_OnDeath(this, Data);
		AutoAimTargetComp.Disable(this);
		ExplosionComp.Explode();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnExploderTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		UCoastBomblingEffectHandler::Trigger_OnTakeDamage(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DeployedDuration += DeltaSeconds;

		if(DeployedDuration > 8)
			HealthComp.Die();
	}
}