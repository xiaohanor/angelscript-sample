class AEggPathDoorOpenBirdsEventManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	ASummitFlyingBirdFlockPosition BirdFlock;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = BirdFlock.BirdMiddleLoc.Value;
	}

	UFUNCTION()
	void ActivateBirdEvent()
	{
		USummitFlyingBirdFlockEventHandler::Trigger_StartDefaultReveal(BirdFlock);
	}
};