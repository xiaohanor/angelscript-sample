event void FOnBasicAIDie(); // should be removed in the next project

UCLASS(Abstract, hideCategories="StartingAnimation Animation Mesh Materials Physics Collision Activation Lighting Shape Navigation Clothing Replication Rendering Cooking Input Actor LOD AssetUserData")
class ABasicAICharacter : AHazeCharacter
{
	// Overlaps are expensive for stuff that moves frequently
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.ShadowPriority = EShadowPriority::AICharacter;

    UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UBasicBehaviourComponent BehaviourComponent;

    UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
	UBasicAITargetingComponent TargetingComponent;
	
    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIAnimationComponent AnimComp;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UBasicAIVoiceOverComponent VoiceComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIRequestOverrideFeatureCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BlockBehavioursWhenControlledByCutsceneCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY(DefaultComponent)
	UAICharacterAudioCrowdControlComponent CrowdControlComp;

	UPROPERTY(DisplayName = "OnDie")
	FOnBasicAIDie OnAIDie;

	UPROPERTY(Category = Audio)
	FSoundDefReference BasicMovementSoundDef;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		// Resetting from respawn binding are done in BasicAIUpdateCapability, here we bind stuff for 
		// triggering events that should be easily accessible from blueprint.
		HealthComp.OnDie.AddUFunction(this, n"OnDeath");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnDamage");
		if(BasicMovementSoundDef.SoundDef.IsValid())
			BasicMovementSoundDef.SpawnSoundDefAttached(this, this);

#if TEST
		auto DebugComp = UAIDebugDisplayComponent::GetOrCreate(this);
#endif
    }

    UFUNCTION(NotBlueprintCallable)
    private void OnDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType Type)
    {
		OnTakeDamage(Attacker, HealthComp.CurrentHealth, Damage, Type);
    }

	UFUNCTION()
	void OnTakeDamage(AHazeActor Attacker, float RemainingHealth, float Damage, EDamageType DamageType)
	{
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnDeath(AHazeActor ActorBeingKilled)
    {
		OnDie();
    }

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDie()
	{
		OnAIDie.Broadcast();
	}
	
	UFUNCTION(BlueprintCallable)
	void BlockBehaviour(FInstigator Instigator)
	{
		BlockCapabilities(BasicAITags::Behaviour, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockBehaviour(FInstigator Instigator)
	{
		UnblockCapabilities(BasicAITags::Behaviour, Instigator);
	}
}

