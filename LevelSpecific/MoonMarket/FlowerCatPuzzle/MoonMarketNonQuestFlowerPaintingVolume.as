class AMoonMarketNonQuestFlowerPaintingVolume : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	ASplineActor PaintingAreaSpline;

	TArray<FMoonMarketFlowerPuzzleOverlapData> FlowerGroups;

	float EraseRadius = 50;
	int MaxAllowedFlowers = 2000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);

		if(FlowerComp.PaintingVolume == this)
		{
			FlowerComp.PaintingVolume = nullptr;
			FlowerComp.bShowPaintingTutorial = false;
			FlowerComp.bShowEraseTutorial = false;
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);
		FlowerComp.PaintingVolume = this;
		FlowerComp.bShowPaintingTutorial = true;
		FlowerComp.bShowEraseTutorial = true;
	}


	bool IsInsidePaintingArea(AHazePlayerCharacter Player) const
	{
		const FVector ClosestLocationOnSpline = PaintingAreaSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
		const FVector DirectionToCenter = (ActorLocation - ClosestLocationOnSpline).GetSafeNormal();
		const FVector DirectionToPlayer = (Player.ActorLocation - ClosestLocationOnSpline).GetSafeNormal();

		if(DirectionToCenter.DotProduct(DirectionToPlayer) <= 0)
			return false;

		return true;
	}

	void EraseFlowers(UMoonMarketPlayerFlowerSpawningComponent FlowerComp, AHazePlayerCharacter Player, FVector EraseLocation)
	{
		for(int i = FlowerGroups.Num() -1; i >= 0; i--)
		{
			// if(FlowerGroups[i].Player != Player)
			// 	continue;
			
			if(FlowerGroups[i].FlowerLocation.DistSquared(EraseLocation) < EraseRadius * EraseRadius)
			{
				UMoonMarketFlowerHatEventHandler::Trigger_OnFlowersErase(FlowerComp.Hat, FMoonMarketFlowerHatEffectParams(Player, FlowerGroups[i].FlowerLocation));
				Niagara::SpawnOneShotNiagaraSystemAtLocation(FlowerComp.ShrivelEffect, FlowerGroups[i].FlowerLocation);

				for(int FlowerID : FlowerGroups[i].FlowerIds)
				{					
					FlowerGroups[i].FlowerComp.RemoveInstance(FlowerID);
				}

				FlowerGroups.RemoveAt(i);
			}
		}
	}
};