class ATundraDancingEnt : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase EntMesh;

	UPROPERTY()
	float DegreesMargin = 5.0;


	TArray<UPrimitiveComponent> PrimitiveComponents;

	bool bDancing = false;
	TPerPlayer<bool> InView;
	TPerPlayer<float> DegreesToView;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
			CheckInView(Player);
		
		if (!InView[Game::Mio] && !InView[Game::Zoe] && !bDancing)
		{
			bDancing = true;
			BP_Dance();
		}

		if ((InView[Game::Mio] || InView[Game::Zoe]) && bDancing)
		{
			bDancing = false;
			BP_StopDance();
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Dance(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StopDance(){}

	private void CheckInView(AHazePlayerCharacter Player)
	{
		DegreesToView[Player] = (ActorLocation - Player.ViewLocation).GetSafeNormal().GetAngleDegreesTo(Player.ViewRotation.ForwardVector);

		float MinDegrees = Player.ViewFOV * 0.5 + DegreesMargin;

		if (Player == Game::Zoe && UTundraPlayerShapeshiftingComponent::Get(Game::Zoe).IsBigShape())
			InView[Player] = false;
		else if (DegreesToView[Player] > MinDegrees)
			InView[Player] = false;
		else
			InView[Player] = true;
	}
};