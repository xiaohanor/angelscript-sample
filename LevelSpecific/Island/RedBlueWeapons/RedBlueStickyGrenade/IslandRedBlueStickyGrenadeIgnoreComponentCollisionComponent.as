/* Attach this component to a component that shouldn't block a sticky grenade explosion */
class UIslandRedBlueStickyGrenadeIgnoreComponentCollisionComponent : USceneComponent
{
	/* If true the grenade will pass right through this component when being thrown */
	UPROPERTY(EditAnywhere)
	bool bAlsoIgnoreForGrenadeMovement = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(AttachParent);
		devCheck(PrimitiveParent != nullptr, "Tried to attach a UIslandRedBlueStickyGrenadeIgnoreComponentCollisionComponent to a component that isn't a primitive component, since this component has no collision this will do nothing.");

		auto Container = UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio);
		Container.IgnoreCollisionComponents.AddUnique(PrimitiveParent);

		if(bAlsoIgnoreForGrenadeMovement)
		{
			Container.IgnoreMovementCollisionComponents.AddUnique(PrimitiveParent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(AttachParent);
		auto Container = UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio);
		Container.IgnoreCollisionComponents.RemoveSingleSwap(PrimitiveParent);

		if(bAlsoIgnoreForGrenadeMovement)
		{
			Container.IgnoreMovementCollisionComponents.RemoveSingleSwap(PrimitiveParent);
		}
	}
}