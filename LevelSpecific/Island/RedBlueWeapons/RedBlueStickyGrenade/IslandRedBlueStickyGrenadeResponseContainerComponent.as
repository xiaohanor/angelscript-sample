UCLASS(NotPlaceable, NotBlueprintable)
class UIslandRedBlueStickyGrenadeResponseContainerComponent : UActorComponent
{
	TArray<UIslandRedBlueStickyGrenadeResponseComponent> ResponseComponents;

	// These will be ignored when tracing from the grenade to grenade response components to determine if the explosion hit them.
	TArray<AActor> IgnoreCollisionActors;
	TArray<UPrimitiveComponent> IgnoreCollisionComponents;

	// These will be ignored when throwing the grenade (the grenade will pass right through them)
	TArray<AActor> IgnoreMovementCollisionActors;
	TArray<UPrimitiveComponent> IgnoreMovementCollisionComponents;
}