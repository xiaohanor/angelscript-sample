namespace HazeGeometryCollection
{
	UFUNCTION(BlueprintPure, Category = "VFX", DisplayName = "Get Haze GeometryCollection Actors")
	TArray<AHazeGeometryCollectionActor> GetActors() 
	{
		return TListedActors<AHazeGeometryCollectionActor>().Array;
	}
}

class AHazeGeometryCollectionActor : AGeometryCollectionActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UFUNCTION(BlueprintCallable)
	void ApplyBreakingVelocityToAllPieces(FVector Vel)
	{
		for(int i = 0; i < 100; ++i)
		{
			GeometryCollectionComponent.ApplyBreakingLinearVelocity(i, Vel);
		}
	}
}