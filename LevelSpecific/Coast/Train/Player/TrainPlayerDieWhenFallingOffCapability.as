class UTrainPlayerDieWhenFallingOffCapability : UHazePlayerCapability
{
	UCoastTrainRiderComponent TrainRiderComp;
	ACoastTrainDriver RelevantTrain;
	UPlayerMovementComponent MoveComp;
	float RidingEnemyTime;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TrainRiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Player.ApplyMovingBalanceBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TrainRiderComp.HasTrains() && !TrainRiderComp.bHasTriggeredImpulseFromFallingOff)
			return false;
		if (Player.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TrainRiderComp.HasTrains() && !TrainRiderComp.bHasTriggeredImpulseFromFallingOff)
			return true;
		if (Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RelevantTrain = nullptr;
		RidingEnemyTime = -BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Has train streamed out?
		if (!TrainRiderComp.IsValidTrain(RelevantTrain))
			RelevantTrain = TrainRiderComp.GetAnyTrain(); 

		if (RelevantTrain != nullptr && !RelevantTrain.IsPlayerOnTrain(Player))
		{
			// Check if we should switch train
			ACoastTrainDriver RidingTrain = TrainRiderComp.GetRidingTrain(Player);
			if (RidingTrain != nullptr)
			{
				// Switch to train that we're on
				RelevantTrain = RidingTrain;
			}
			else 
			{
				// We're not on any train, switch to any train that can kill us
				ACoastTrainDriver KillyTrain = TrainRiderComp.GetTrainKillingPlayers();
				if (KillyTrain != nullptr)
					RelevantTrain = KillyTrain;
			}
		}

		if (ShouldKillPlayer())
			Player.KillPlayer(); 
	}

	bool ShouldKillPlayer()
	{
		if (!RelevantTrain.ShouldKillPlayerFallingOffTrain())
			return false;
				
		// At train?
		ACoastTrainCart ClosestCart = RelevantTrain.GetCartClosestToPlayer(Player);
		if (ClosestCart == nullptr)
			return true;

		// Below kill height?
		if (RelevantTrain != nullptr)
		{
			float KillHeight = RelevantTrain.GetKillPlayerBelowTrainHeight(); 
			if (ClosestCart.ActorLocation.Z - KillHeight > Player.ActorLocation.Z)
				return true;
		}

		// Bumped into something not moving with train?
		if (HasOffTrainImpact())
			return true;

		return false;
	}

	bool HasOffTrainImpact()
	{
		if (Time::GetGameTimeSince(RidingEnemyTime) < 0.5)
			return false; // Enjoy immunity to being csraped off by stuff while riding enemies for now.

		if (!MoveComp.HasAnyValidBlockingContacts())
			return false;

		FMovementHitResult Impact = MoveComp.GroundContact;
		if (!Impact.IsValidBlockingHit())
		{
			Impact = MoveComp.WallContact;
			if (!Impact.IsValidBlockingHit())
				Impact = MoveComp.CeilingContact; 
		}

		if (Impact.IsNotValid())
			return false;

		AActor ImpactActor = Impact.Actor;
		if (ImpactActor == nullptr)
			return true; // Hit bsp!

		// If we hit train cart or something attached to train cart we're all good 	
		while (ImpactActor.AttachParentActor != nullptr)
		{
			if (ImpactActor.IsA(ACoastTrainCart))
				return false; // There are carts attached to spline for some reason
			ImpactActor = ImpactActor.AttachParentActor;
		}
		if (ImpactActor.IsA(ACoastTrainCart))
			return false; 

		if (UBasicAIHealthComponent::Get(Impact.Actor) != nullptr)
		{
			RidingEnemyTime = Time::GameTimeSeconds;
			return false; // Hit an enemy, ignore
		}

		// We've smacked into something off the train, splat!
		return true;
	}
}
