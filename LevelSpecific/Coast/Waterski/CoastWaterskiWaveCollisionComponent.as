// Place this component on any actors whose collision should act like water instead of normal collision
class UCoastWaterskiWaveCollisionComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UCoastWaterskiWaveCollisionContainerComponent::GetOrCreate(Game::Mio).WaveCollisionComponents.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UCoastWaterskiWaveCollisionContainerComponent::GetOrCreate(Game::Mio).WaveCollisionComponents.RemoveSingleSwap(this);
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UCoastWaterskiWaveCollisionContainerComponent : UActorComponent
{
	TArray<UCoastWaterskiWaveCollisionComponent> WaveCollisionComponents;
}