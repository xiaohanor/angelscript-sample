class ASkylineCarChasePylon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleOnActivated");
	}

	UFUNCTION()
	private void HandleOnActivated(AActor Caller)
	{
		HandleActivatedBP();
	}

	UFUNCTION(BlueprintEvent)
	void HandleActivatedBP()
	{
	}
};