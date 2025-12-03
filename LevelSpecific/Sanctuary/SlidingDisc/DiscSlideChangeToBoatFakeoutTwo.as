class ADiscSlideChangeToBoatFakeoutTwo : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASanctuaryBoat Boat;


	UPROPERTY(EditAnywhere)
	AActor RefActor;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Game::Mio.GetDistanceTo(RefActor) < 200.0 && bDoOnce)
		{
			Boat.ClearAllDisables();
			bDoOnce = false;
		}

		if (SlidingDiscDevToggles::DrawBoat.IsEnabled())
			PrintToScreen("Distamce: " + Game::Mio.GetDistanceTo(RefActor));
	}
};