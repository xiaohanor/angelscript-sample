UCLASS(Abstract)
class AAIIslandDyad : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandDyadBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandDyadForceFieldCapability");

	default MoveToComp.DefaultSettings = BasicAICharacterGroundPathfollowingSettings;

	UPROPERTY(DefaultComponent)
	UIslandDyadLaserComponent LaserComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent RedBlueTargetableComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandDyadDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerKnockdownSheet); 

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;	

	AAIIslandDyad GetOtherDyad() property
	{
		return LaserComp.OtherDyad;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HealthComp.OnDie.AddUFunction(this, n"OnDyadDie");

		if(RespawnComp.Spawner != nullptr)
		{
			auto SpawnerHealthComp = UBasicAIHealthComponent::Get(RespawnComp.Spawner);
			if(SpawnerHealthComp != nullptr)
				SpawnerHealthComp.OnDie.AddUFunction(this, n"OnSpawnerDie");
		}
		
		this.JoinTeam(IslandDyadTags::IslandDyadTeam);
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
	private void OnDyadDie(AHazeActor ActorBeingKilled)
	{
		UIslandDyadEffectHandler::Trigger_OnDeath(this);
	}
}

namespace IslandDyadTags
{
	const FName IslandDyadTeam = n"IslandDyadTeam";
}