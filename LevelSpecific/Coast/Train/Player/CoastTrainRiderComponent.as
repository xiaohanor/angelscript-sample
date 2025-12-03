class UCoastTrainRiderComponent : UActorComponent
{
	private TArray<ACoastTrainDriver> TrainDrivers;

	ACoastTrainCart ReachedTrainCart;
	float ReachedTrainCartPosition = 0.0;

	ACoastTrainCart CurrentTrainCart;
	float CurrentTrainCartPosition = 0.0;

	bool bHasTriggeredImpulseFromFallingOff = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Reset "fall off" impulse when player has respawned
		if (bHasTriggeredImpulseFromFallingOff)
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			if (Player.IsPlayerDead())
			{
				Player.UnblockCapabilities(PlayerMovementTags::Grapple, n"FellOffTrain");
				bHasTriggeredImpulseFromFallingOff = false;
			}
		}
	}

	void TriggerFallOffTrain()
	{
		bHasTriggeredImpulseFromFallingOff = true;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(PlayerMovementTags::Grapple, n"FellOffTrain");
	}

	void Register(ACoastTrainDriver Train)
	{
		if (!IsValid(Train))
			return;
		TrainDrivers.AddUnique(Train);
	}

	void Unregister(ACoastTrainDriver Train)
	{
		TrainDrivers.RemoveSingleSwap(Train);
	}

	bool IsValidTrain(ACoastTrainDriver Train) const
	{
		if (!IsValid(Train))
			return false;
		if (!TrainDrivers.Contains(Train))
			return false;
		return true;
	}

	ACoastTrainDriver GetRidingTrain(AHazePlayerCharacter Player) const
	{
		for (ACoastTrainDriver Train : TrainDrivers)
		{
			if (Train.IsPlayerOnTrain(Player))
				return Train;
		}
		return nullptr;
	}

	ACoastTrainDriver GetTrainKillingPlayers() const
	{
		for (ACoastTrainDriver Train : TrainDrivers)
		{
			if (Train.ShouldKillPlayerFallingOffTrain())
				return Train;
		}
		return nullptr;
	}

	bool HasTrains() const
	{
		return (TrainDrivers.Num() > 0);
	}

	ACoastTrainDriver GetAnyTrain() const
	{
		if (!HasTrains())	
			return nullptr;
		return TrainDrivers[0];
	}

	float GetDistanceToDriver() const property
	{
		if (CurrentTrainCart == nullptr)
			return BIG_NUMBER;
		return CurrentTrainCart.SplineDistanceFromDriver - CurrentTrainCart.ActorForwardVector.DotProduct(Owner.ActorLocation - CurrentTrainCart.ActorLocation);
	}
}

