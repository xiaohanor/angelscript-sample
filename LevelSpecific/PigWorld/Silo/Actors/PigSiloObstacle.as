class APigSiloObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComponent;

	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	UHazeMovablePlayerTriggerComponent MovableTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovableTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerCollision");
	}

	UFUNCTION()
	private void OnPlayerCollision(AHazePlayerCharacter Player)
	{
		UPlayerPigSiloComponent PlayerPigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		if (PlayerPigSiloComponent != nullptr)
		{
			PlayerPigSiloComponent.OnObstacleCollision.Broadcast(this);
		}

		UPigSiloObstacleEventHandler::Trigger_OnDestroyed(this);

		BP_Destroyed();

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroyed() {}
}