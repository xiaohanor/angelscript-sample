asset SkylineExploderGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2200.0;
}

UCLASS(Abstract)
class AAISkylineExploder : ABasicAIGroundMovementCharacter
{
	default CapsuleComponent.bGenerateOverlapEvents = true; // TODO: Remove!
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineExploderBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineExploderRollCapability");

	UPROPERTY(DefaultComponent)
	USkylineExploderDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	USkylineExploderRollComponent RollComp;

	UPROPERTY(DefaultComponent)
	USkylineExploderExplosionComp ExplosionComp;

	USkylineExploderSettings ExploderSettings;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplySettings(SkylineExploderGravitySettings, this, EHazeSettingsPriority::Defaults);
		UGravityWhippableSettings::SetEnableThrownDamage(this, false, this);
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);

		ExploderSettings = USkylineExploderSettings::GetSettings(this);

		HealthComp.OnDie.AddUFunction(this, n"OnExploderDie");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnExploderTakeDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReset()
	{
		USkylineExploderEffectHandler::Trigger_OnRespawn(this);

		WhipTarget.Enable(this);
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	private void OnExploderDie(AHazeActor ActorBeingKilled)
	{
		auto Data = FSkylineExploderEffectOnDeathData();
		Data.DeathDuration = ExploderSettings.DeathDuration;
		USkylineExploderEffectHandler::Trigger_OnDeath(this, Data);
		WhipTarget.Disable(this);
		ExplosionComp.Explode();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnExploderTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		USkylineExploderEffectHandler::Trigger_OnTakeDamage(this);
	}
}