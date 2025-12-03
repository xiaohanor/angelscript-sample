asset SmasherMovementSettings of UBasicAIMovementSettings
{
	TurnDuration = 2.0;
}

UCLASS(Abstract, meta = (DefaultActorLabel = "Smasher"))
class AAISummitSmasher : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherMeltedSwitchControlSideCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherTargetingSwitchControlSideCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent)
	UTeleportTraversalComponent TraversalComp;
	default TraversalComp.Method = USummitBurrowTraversalMethod;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(PlayerTraversalSheet);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplyDefaultSettings(SmasherMovementSettings);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnRollAttack");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		USmasherEventHandler::Trigger_OnSpawn(this);

		MeltingComp.OnMelted.AddUFunction(this, n"OnMelted");
		MeltingComp.OnRestored.AddUFunction(this, n"OnRestored");

		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
	}

	UFUNCTION()
	private void OnDieEvent(AHazeActor ActorBeingKilled)
	{
		USmasherEventHandler::Trigger_OnDeath(this);
	}

	UFUNCTION()
	private void OnRestored()
	{
		USmasherEventHandler::Trigger_OnArmorRestored(this);
	}

	UFUNCTION()
	private void OnMelted()
	{
		USmasherEventHandler::Trigger_OnArmorMelted(this);
	}

	UFUNCTION()
	private void OnReset()
	{
		USmasherEventHandler::Trigger_OnSpawn(this);
	}

	UFUNCTION()
	private void OnRollAttack(FRollParams Params)
	{
		MovementComponent.AddPendingImpulse(Params.RollDirection * 100.0);
		HealthComp.TakeDamage(1000, EDamageType::MeleeBlunt, Params.PlayerInstigator);
	}
}
