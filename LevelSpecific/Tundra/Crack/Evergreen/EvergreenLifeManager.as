event void FEvergreenLifeManagerEventNoParams();

class AEvergreenLifeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(DefaultComponent)
	UTundraGroundedLifeReceivingTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	FEvergreenLifeManagerEventNoParams OnNetInteractStartDuringLifeGive;

	UPROPERTY()
	FEvergreenLifeManagerEventNoParams OnNetInteractStopDuringLifeGive;

	private AEvergreenLifeNetworkedEventCaller EventCaller;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EventCaller = SpawnActor(AEvergreenLifeNetworkedEventCaller, bDeferredSpawn = true);
		EventCaller.MakeNetworked(this, n"_EventCaller");
		EventCaller.Manager = this;
		FinishSpawningActor(EventCaller);
	}
}

class AEvergreenLifeNetworkedEventCaller : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	AEvergreenLifeManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		Manager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"OnInteractStartDuringLifeGive");
		Manager.LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"OnInteractStopDuringLifeGive");
	}

	UFUNCTION()
	private void OnInteractStartDuringLifeGive()
	{
		if(Network::IsGameNetworked() && HasControl())
			return;

		NetOnInteractStartDuringLifeGive();
	}

	UFUNCTION()
	private void OnInteractStopDuringLifeGive()
	{
		if(Network::IsGameNetworked() && HasControl())
			return;

		NetOnInteractStopDuringLifeGive();
	}

	UFUNCTION(NetFunction)
	private void NetOnInteractStartDuringLifeGive()
	{
		if(Manager == nullptr)
			return;

		Manager.OnNetInteractStartDuringLifeGive.Broadcast();
	}

	UFUNCTION(NetFunction)
	private void NetOnInteractStopDuringLifeGive()
	{
		// Restarting from checkpoint will make manager null
		if(Manager == nullptr)
			return;

		Manager.OnNetInteractStopDuringLifeGive.Broadcast();
	}
}