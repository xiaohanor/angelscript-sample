class ASkylineMallChaseRespawnPoint : ARespawnPoint
{
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	AActor ActorWithSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
//		Super::BeginPlay();

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnTriggerActivate.AddUFunction(this, n"HandleTriggerActivate");
/*
		if (ActorWithSpline != nullptr)
		{
			auto Spline = UHazeSplineComponent::Get(ActorWithSpline);
			if (Spline != nullptr)
			{
				auto AlongSplineComp = USkylineMallChaseAlongSplineComponent::Create(ActorWithSpline);				
				AlongSplineComp.ActorWithSkylineInteface = this;
				AlongSplineComp.WorldLocation = ActorLocation;
				AlongSplineComp.SnapToSpline(Spline);
			}
		}
*/
	}

	UFUNCTION()
	private void HandleTriggerActivate(AActor Caller)
	{
		PrintToScreen("RespawnPoint Disabled" + Name, 3.0, FLinearColor::Green);

		for (auto Player : Game::Players)
			DisableForPlayer(Player, Player);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		PrintToScreen("RespawnPoint Disabled" + Name, 3.0, FLinearColor::Green);

		for (auto Player : Game::Players)
			DisableForPlayer(Player, Player);
	}
};