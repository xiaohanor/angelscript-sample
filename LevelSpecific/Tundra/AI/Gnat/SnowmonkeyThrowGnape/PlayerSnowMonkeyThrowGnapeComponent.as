class UPlayerSnowMonkeyThrowGnapeComponent : UActorComponent
{
	AHazeActor GrabbedGnape = nullptr;
	bool bThrow = false;
	
	TArray<AHazeActor> Gnapes;

	void RegisterThrowableGnape(AHazeActor Gnape)
	{
		Gnapes.AddUnique(Gnape);
	}
	void UnregisterThrowableGnape(AHazeActor Gnape)
	{
		Gnapes.RemoveSingle(Gnape);
	}
};
