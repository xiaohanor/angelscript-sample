UCLASS(Abstract)
class AIslandSidescrollerOneWayPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamicIgnoreProjectiles";

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			UIslandSidescrollerComponent::GetOrCreate(Player).OneWayPlatforms.Add(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::Players)
		{
			auto Comp = UIslandSidescrollerComponent::Get(Player);
			if(Comp == nullptr)
				continue;

			Comp.OneWayPlatforms.RemoveSingleSwap(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(auto Player : Game::Players)
		{
			auto Comp = UIslandSidescrollerComponent::Get(Player);
			if(Comp == nullptr)
				continue;
			
			Comp.OneWayPlatforms.RemoveSingleSwap(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(auto Player : Game::Players)
		{
			UIslandSidescrollerComponent::GetOrCreate(Player).OneWayPlatforms.Add(this);
		}
	}
}