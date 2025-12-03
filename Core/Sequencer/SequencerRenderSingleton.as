

class UHazeSequenceRenderSingleton : UHazeSequenceRenderBaseSingleton
{
	TWeakObjectPtr<AHazeActor> TeenDragonMio;
	TWeakObjectPtr<AHazeActor> TeenDragonZoe;

	TWeakObjectPtr<AHazeActor> AdultDragonMio;
	TWeakObjectPtr<AHazeActor> AdultDragonZoe;

	UFUNCTION(BlueprintOverride)
	AHazeActor GetMioTeenDragon()
	{
		return TeenDragonMio.Get();
	}

	UFUNCTION(BlueprintOverride)
	AHazeActor GetZoeTeenDragon()
	{
		return TeenDragonZoe.Get();
	}

	UFUNCTION(BlueprintOverride)
	AHazeActor GetMioAdultDragon()
	{
		return AdultDragonMio.Get();
	}

	UFUNCTION(BlueprintOverride)
	AHazeActor GetZoeAdultDragon()
	{
		return AdultDragonZoe.Get();
	}
}