// All spawned actors from patterns of lower update order join set team
UCLASS(meta = (ShortTooltip="All spawned actors join set team."))
class UHazeActorSpawnPatternJoinTeam : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	FName TeamName = NAME_None;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	TSubclassOf<UHazeTeam> TeamClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (TeamName.IsNone() && !TeamClass.IsValid())
		{
			// Uninitialized, this will not have any effect
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}

		if (TeamName.IsNone())
			TeamName = FName(Owner.Name + "_" + this.Name);

		// As joining team is deterministic, we don't need to include this in spawn parameters
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
			Spawner.OnPostUnspawn.AddUFunction(this, n"OnAnyPatternUnspawn");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (IsActivePattern())
			Spawn.JoinTeam(TeamName, TeamClass);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		Spawn.LeaveTeam(TeamName);
	}
}
