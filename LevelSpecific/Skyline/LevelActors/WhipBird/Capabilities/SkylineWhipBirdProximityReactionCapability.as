class USkylineWhipBirdProximityReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdReaction");
	default CapabilityTags.Add(n"SkylineWhipBirdProximityReaction");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineWhipBird WhipBird;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipBird = Cast<ASkylineWhipBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsPlayerInProximity())
			return false;

		if (DeactiveDuration < 1.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 1.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("React!", 1.0, FLinearColor::Red);
		FSkylineBirdEventData EventData;
		float ClosestDistance = MAX_flt;

		for (auto Player : Game::Players)
		{
			float Distance = Player.GetDistanceTo(WhipBird);
			if (Distance < WhipBird.ProximityRadius)
			{
				FVector ToPlayer = WhipBird.ActorLocation - Player.ActorLocation;

				WhipBird.ActorVelocity += ToPlayer.SafeNormal * 2500.0;
			}

			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				EventData.Player = Player;
			}
		}

		if (WhipBird.bIsSitting) // Was sitting
			USkylineWhipBirdEventHandler::Trigger_OnFlyAway(WhipBird, EventData);

		WhipBird.BlockCapabilities(n"SkylineWhipBirdLand", this);
		WhipBird.BlockCapabilities(n"SkylineWhipBirdSit", this);

		WhipBird.ClearTarget();

		WhipBird.SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdLand", this);
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdSit", this);

		WhipBird.UpdateTarget();

		WhipBird.SetActorEnableCollision(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	bool IsPlayerInProximity() const
	{
		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(WhipBird) < WhipBird.ProximityRadius)
				return true;
		}

		return false;
	}
};