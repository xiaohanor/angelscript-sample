class ATundraFishieHuntingZone : APlayerTrigger
{
	default bTriggerForMio = true;
	default bTriggerForZoe = false;
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.6, 0.3, 0.0, 1.0));

	UPROPERTY(EditInstanceOnly)
	TArray<AAITundraChasingFishie> Fishies;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	TArray<FVector> ReturnWaypoints;
	default ReturnWaypoints.Add(FVector(6.0, 85.0, 50.0));
	default ReturnWaypoints.Add(FVector(6.0, -90.0, -60.0));

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		for (AAITundraChasingFishie Fishie : Fishies)
		{
			if (Fishie == nullptr)
				continue;
			Fishie.FishieComp.bHasHuntingZones = true;
		}		

		// Move waypoints into world space
		for (FVector& Waypoint : ReturnWaypoints)
		{
			Waypoint = ActorTransform.TransformPosition(Waypoint);
		}
	}

	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		if (!Player.IsMio())
			return;
		for (AAITundraChasingFishie Fishie : Fishies)
		{
			Fishie.FishieComp.ActiveHuntingZones.AddUnique(this);
		}		
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);

		if (!Player.IsMio())
			return;
		for (AAITundraChasingFishie Fishie : Fishies)
		{
			Fishie.FishieComp.ActiveHuntingZones.RemoveSingleSwap(this);
		}		
	}
};

