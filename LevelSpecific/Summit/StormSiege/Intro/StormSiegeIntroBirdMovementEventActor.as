class AStormSiegeIntroBirdMovementEventActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(20.0));
#endif

	UFUNCTION()
	void ActivateEvent(ASummitFlyingBirdFlockPosition Flock)
	{
		USummitFlyingBirdFlockEventHandler::Trigger_StartDefaultReveal(Flock);
	}
};