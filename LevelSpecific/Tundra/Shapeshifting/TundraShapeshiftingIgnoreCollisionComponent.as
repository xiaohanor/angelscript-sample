/* Place this component on actors that should be ignored by the collision checking that the shapeshifting system does. */
class UTundraShapeshiftingIgnoreCollisionComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto MioContainerComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::GetOrCreate(Game::Mio);
		auto ZoeContainerComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::GetOrCreate(Game::Zoe);

		MioContainerComp.ActorsToIgnore.AddUnique(Owner);
		ZoeContainerComp.ActorsToIgnore.AddUnique(Owner);
	}
}