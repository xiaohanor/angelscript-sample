// Applies landing scenepoints to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Hej"))
class USkylineEnforcerSpawnPatternActivationTrigger : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	TArray<UAnimSequence> IdleAnimations;

	int SpawnIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Applying settings is deterministic, we need not include this in spawn parameters
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
			Spawner.OnPostUnspawn.AddUFunction(this, n"OnAnyPatternUnspawn");
		}
	
		if (Trigger != nullptr)
			Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		Trigger.OnPlayerEnter.Unbind(this, n"HandlePlayerEnter");

		auto Spawner = UHazeActorSpawnerComponent::Get(Owner);

		for (auto Member : Spawner.SpawnedActorsTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;

			Member.UnblockCapabilities(n"Behaviour", this);

			if (IdleAnimations.Num() > 0)
				Member.StopSlotAnimation();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (IsActivePattern())
		{
			Spawn.BlockCapabilities(n"Behaviour", this);

			if (IdleAnimations.Num() > 0)
			{
				auto Animation = IdleAnimations[Math::WrapIndex(SpawnIndex, 0, IdleAnimations.Num())];
				Spawn.PlaySlotAnimation(Animation = Animation, bLoop = true); // StartTime = Math::Wrap(Spawn.ActorLocation.Size(), 0.0, Animation.PlayLength)
			}

			SpawnIndex++;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{

	}
}
