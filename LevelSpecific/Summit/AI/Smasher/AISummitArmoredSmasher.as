UCLASS(Abstract, meta = (DefaultActorLabel = "ArmoredSmasher"))
class AAISummitArmoredSmasher : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitArmoredSmasherBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherMeltedSwitchControlSideCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherTargetingSwitchControlSideCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SmasherMovementCapability"); 

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent)
	UTeleportTraversalComponent TraversalComp;
	default TraversalComp.Method = USummitBurrowTraversalMethod;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(PlayerTraversalSheet);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = Crystal)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hand")
	USmasherMeleeComponent MeleeComp;

	UPROPERTY(DefaultComponent)
	USummitSmasherJumpAttackComponent JumpAttackComp;

	UPROPERTY(DefaultComponent)
	USummitSmasherPauseMovementComponent PauseMovementComp;

	UPROPERTY(DefaultComponent)
 	UHazeCrumbSyncedActorPositionComponent SyncedMovementPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplyDefaultSettings(SmasherMovementSettings);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnRollAttack");
		MeltingComp.OnMelted.AddUFunction(this, n"OnMelted");
		MeltingComp.OnRestored.AddUFunction(this, n"OnRestored");
		TailAttackResponseComp.bShouldStopPlayer = true;

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		Timer::SetTimer(this, n"DelayedSpawn", 0.1);
	}

	UFUNCTION()
	private void DelayedSpawn()
	{
		USmasherEventHandler::Trigger_OnSpawn(this);
	}

	UFUNCTION()
	private void OnRestored()
	{
	//	TailAttackResponseComp.bShouldStopPlayer = true;
		USmasherEventHandler::Trigger_OnArmorRestored(this);
	}

	UFUNCTION()
	private void OnMelted()
	{
		//TailAttackResponseComp.bShouldStopPlayer = false;
		USmasherEventHandler::Trigger_OnArmorMelted(this);
	}

	UFUNCTION()
	private void OnRollAttack(FRollParams Params)
	{
		if(!MeltingComp.bMelted)
			return;

		HealthComp.TakeDamage(1000, EDamageType::MeleeBlunt, Params.PlayerInstigator);
		USmasherEventHandler::Trigger_OnDeath(this);
	}

	UFUNCTION(DevFunction)
	void AggroMode()
	{
		ApplySettings(SmasherAggroSettings, n"AggroMode", EHazeSettingsPriority::Gameplay);
		ApplySettings(SmasherAggroMeltSettings, n"AggroMode", EHazeSettingsPriority::Gameplay);
	}
	UFUNCTION(DevFunction)
	void ClearAggroMode()
	{
		ClearSettingsByInstigator(n"AggroMode");
	}

	UFUNCTION(DevFunction)
	void Kill()
	{
		MeltingComp.Health = 0.0;
		MeltingComp.UpdateMeltAlpha();
		OnRollAttack(FRollParams());
	}
}

asset SmasherAggroSettings of USmasherSettings
{
	JumpAttackAnimDurationScale = 0.8;

	AttackAnimDurationScale = 0.8;
	AttackCooldown = 0.0;
	AttackSuccessExtraCooldown = 0.0;
	AttackGentlemanCooldown = 0.0;
}

asset SmasherAggroMeltSettings of USummitMeltSettings
{
	StayDissolvedDuration = 2.0;
	StayMeltedDuration = 1.0;
}
