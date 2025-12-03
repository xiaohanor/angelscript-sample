class UCoastWaterJetComponent : UActorComponent
{
	ACoastTrainDriver Train;
	FSplinePosition RailPosition;
	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner); 
		OnRespawn();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
		{
			Train = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor).Driver;
			return;
		}
		if (Owner.AttachParentActor != nullptr)
		{
			Train = Cast<ACoastTrainCart>(Owner.AttachParentActor).Driver;
			return;
		}
		for (AHazePlayerCharacter Player: Game::Players)
		{
			UCoastWaterskiPlayerComponent WaterSkiComp = UCoastWaterskiPlayerComponent::Get(Player);
			if ((WaterSkiComp != nullptr) && (WaterSkiComp.CurrentWaterskiAttachPoint != nullptr))
			{
				ACoastTrainCart TrainCart = Cast<ACoastTrainCart>(WaterSkiComp.CurrentWaterskiAttachPoint.Owner);
				if (TrainCart == nullptr)
					TrainCart = Cast<ACoastTrainCart>(WaterSkiComp.CurrentWaterskiAttachPoint.Owner.AttachParentActor);
				if (TrainCart != nullptr)
					Train = TrainCart.Driver;
				if (Train != nullptr)
					return;
			}
		}
		
		float ClosestDistSqr = BIG_NUMBER;
		ACoastTrainDriver ClosestTrain = nullptr;
		TListedActors<ACoastTrainDriver> Trains;
		for (ACoastTrainDriver TrainDriver : Trains)
		{
			float DistSqr = Owner.ActorLocation.DistSquared2D(TrainDriver.ActorLocation);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				ClosestTrain = TrainDriver;
			}
		}

		Train = ClosestTrain;
	}
}
