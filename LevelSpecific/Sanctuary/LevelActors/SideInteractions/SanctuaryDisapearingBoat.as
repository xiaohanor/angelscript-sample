class ASanctuaryDisapearingBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float DegreesMargin = 3.0;

	TArray<UPrimitiveComponent> PrimitiveComponents;

	TPerPlayer<bool> HiddenForPlayer;

	TPerPlayer<float> DegreesToView;
	TPerPlayer<float> LastFrameDegreesToView;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.GetChildrenComponentsByClass(UPrimitiveComponent, true, PrimitiveComponents);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			LastFrameDegreesToView[Player] = DegreesToView[Player];
			DegreesToView[Player] = (ActorLocation - Player.ViewLocation).GetSafeNormal().GetAngleDegreesTo(Player.ViewRotation.ForwardVector);

			if (BecameOutOfView(Player))
			{
				SwitchRenderForPlayer(Player);
			}
		}
	}

	private void SwitchRenderForPlayer(AHazePlayerCharacter Player)
	{
		HiddenForPlayer[Player] = !HiddenForPlayer[Player];

		for (auto PrimitiveComponent : PrimitiveComponents)
		{
			PrimitiveComponent.SetRenderedForPlayer(Player, HiddenForPlayer[Player]);
		}
	}

	private bool BecameOutOfView(AHazePlayerCharacter Player)
	{
		float MinDegrees = Player.ViewFOV * 0.5 + DegreesMargin;

		if (DegreesToView[Player] > MinDegrees)
		{
			if (LastFrameDegreesToView[Player] < MinDegrees)
			{
				return true;
			}
		}

		return false;
	}
};