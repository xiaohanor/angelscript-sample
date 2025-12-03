class AIslandPortalVisual : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AIslandPortal PortalRef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
					// ListenerRef.OnCompleted.AddUFunction(this, n"HandleCompleted");

		if (PortalRef != nullptr)
			PortalRef.OnPortalClosed.AddUFunction(this, n"HandlePortalClosed");
	}

	UFUNCTION()
	void HandlePortalClosed()
	{
		BP_HandlePortalClosed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandlePortalClosed()
	{}
};