class AExampleListedActor : AActor
{
	/**
	 * Adding a UHazeListedActorComponent to an actor makes it possible to
	 * look up all actors in a list.
	 */
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}

void Example_GetActorsInList()
{
	// You can find all actors listed by the component:
	TListedActors<AExampleListedActor> ListedActors;
	for (AExampleListedActor Actor : ListedActors)
	{
	}

	// For managers, you might want to get just one actor instead:
	AExampleListedActor ExampleManager = TListedActors<AExampleListedActor>().GetSingle();
}

// For managers, it can be helpful to add a helper function to look it up from the list:
namespace AExampleListedActor
{
	// Get the example listed actor in the level
	AExampleListedActor GetManager()
	{
		return TListedActors<AExampleListedActor>().GetSingle();
	}
}