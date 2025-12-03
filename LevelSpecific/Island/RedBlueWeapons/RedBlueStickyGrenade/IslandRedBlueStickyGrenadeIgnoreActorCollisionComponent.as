/* Attach this component to a actor that shouldn't block a sticky grenade explosion */
class UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent : UActorComponent
{
	/* If true the grenade will pass right through this actor when being thrown */
	UPROPERTY(EditAnywhere)
	bool bAlsoIgnoreForGrenadeMovement = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Container = UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio);
		Container.IgnoreCollisionActors.AddUnique(Owner);

		if(bAlsoIgnoreForGrenadeMovement)
		{
			Container.IgnoreMovementCollisionActors.AddUnique(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Container = UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio);
		Container.IgnoreCollisionActors.RemoveSingleSwap(Owner);

		if(bAlsoIgnoreForGrenadeMovement)
		{
			Container.IgnoreMovementCollisionActors.RemoveSingleSwap(Owner);
		}
	}
}