enum ESpawnPatternAggroTarget
{
	Mio,
	Zoe,
	Closest
}

// All spawned actors will immediately start targeting given player
UCLASS(meta = (ShortTooltip="All spawned actors will immediately start targeting given player"))
class UHazeActorSpawnPatternAggroPlayer : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	ESpawnPatternAggroTarget AggroTarget = ESpawnPatternAggroTarget::Closest;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Aggro will only have effect on control side 
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (IsActivePattern())
		{
			UBasicAITargetingComponent TargetingComp = UBasicAITargetingComponent::Get(Spawn);
			if (TargetingComp == nullptr)
				return;
			AHazePlayerCharacter Player;
			switch (AggroTarget)
			{
				case ESpawnPatternAggroTarget::Mio:
					TargetingComp.SetAggroTarget(Game::Mio);
					break;
				case ESpawnPatternAggroTarget::Zoe:
					TargetingComp.SetAggroTarget(Game::Zoe);
					break;
				case ESpawnPatternAggroTarget::Closest:
				{
					FVector SpawnLoc = Spawn.ActorCenterLocation;
					if (Game::Mio.ActorCenterLocation.DistSquared(SpawnLoc) < Game::Zoe.ActorCenterLocation.DistSquared(SpawnLoc))
						TargetingComp.SetAggroTarget(Game::Mio);
					else
						TargetingComp.SetAggroTarget(Game::Zoe);
					break;
				}
			}
		}
	}
}
