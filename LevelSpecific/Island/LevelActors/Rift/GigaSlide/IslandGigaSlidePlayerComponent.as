UCLASS(NotPlaceable)
class UIslandGigaSlidePlayerComponent : UActorComponent
{
	TArray<AActor> IgnoreCollisionActors;

	bool IsImpactRelevant(FMovementHitResult Impact)
	{
		if(IgnoreCollisionActors.Contains(Impact.Actor))
			return false;

		return true;
	}
}