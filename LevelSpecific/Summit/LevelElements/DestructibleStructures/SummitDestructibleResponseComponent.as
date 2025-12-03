event void FOnSummitDestructibleDestroyed();

class USummitDestructibleResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSummitDestructibleDestroyed OnSummitDestructibleDestroyed;
}