UCLASS(Abstract)
class AAIIslandBuzzer : ABasicAIFlyingCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandBuzzerBehaviourCompoundCapability");

	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent Laser;

	UPROPERTY(DefaultComponent)
	UIslandBuzzerLaserAimingComponent LaserAimingComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent RedBlueTargetableComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandBuzzerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerKnockdownSheet); 

	bool bHasTriggeredDeathEffect = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HealthComp.OnDie.AddUFunction(this, n"OnBuzzerDie");
		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnBuzzerRemoteDeath");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnBuzzerRespawn");

		if(RespawnComp.Spawner != nullptr)
		{
			auto SpawnerHealthComp = UBasicAIHealthComponent::Get(RespawnComp.Spawner);
			if(SpawnerHealthComp != nullptr)
				SpawnerHealthComp.OnDie.AddUFunction(this, n"OnSpawnerDie");
		}

		auto Settings = UBasicAISettings::GetSettings(this);
		UBasicAISettings::SetFlyingChaseHeight(this, Settings.FlyingChaseHeight + Math::RandRange(-150,150), this);

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this);

		this.JoinTeam(IslandBuzzerTags::IslandBuzzerTeam);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UBasicAISettings::ClearFlyingChaseHeight(this, this);
	}

	UFUNCTION()
	private void OnSpawnerDie(AHazeActor ActorBeingKilled)
	{
		HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, ActorBeingKilled);
	}

	UFUNCTION()
	private void OnBuzzerDie(AHazeActor ActorBeingKilled)
	{
		if (!bHasTriggeredDeathEffect)
			UIslandBuzzerEffectHandler::Trigger_OnDeath(this);
		bHasTriggeredDeathEffect = true;
	}

	UFUNCTION()
	private void OnBuzzerRemoteDeath()
	{
		if (!bHasTriggeredDeathEffect)
			UIslandBuzzerEffectHandler::Trigger_OnDeath(this);
		bHasTriggeredDeathEffect = true;
	}

	UFUNCTION()
	private void OnBuzzerRespawn()
	{
		bHasTriggeredDeathEffect = false;
	}
}

namespace IslandBuzzerTags
{
	const FName IslandBuzzerTeam = n"IslandBuzzerTeam";
}