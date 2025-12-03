namespace AIVoiceOver
{
	// Get ID number (not unique since we have a separate counter for each class).
    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
    int GetVoiceId(UObject Handler)
    {
		// Called from BP derived class
		auto Owner = Cast<ABasicAICharacter>(Handler);
        if (Owner != nullptr)
		{
			UBasicAIVoiceOverComponent VOComp = UBasicAIVoiceOverComponent::Get(Owner);
			return VOComp.GetVoiceOverID();
		}

		// Called from EBP
		auto EventHandler = Cast<UHazeEffectEventHandler>(Handler);
        if (EventHandler != nullptr)
        {
            return UBasicAIVoiceOverComponent::Get(EventHandler.Owner).GetVoiceOverID();
        }

		// Called from SoundDef
	    auto SoundDef = Cast<USoundDefBase>(Handler);
        if (SoundDef != nullptr)
        {
            return UBasicAIVoiceOverComponent::Get(SoundDef.HazeOwner).GetVoiceOverID();
        }

		devCheck(false, "Could not cast event handler to extract VoiceOverID.");
        return -1;
    }

	// Get Class string.
	UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
    FString GetVoiceIdClassName(UObject Handler)
    {
		// Called from BP derived class
		auto Owner = Cast<ABasicAICharacter>(Handler);
        if (Owner != nullptr)
		{
			return Owner.Class.Name.ToString();
		}

		// Called from EBP
        auto EventHandler = Cast<UHazeEffectEventHandler>(Handler);
        if (EventHandler != nullptr)
        {
            return EventHandler.Owner.Class.Name.ToString();
        }

		// Called from SoundDef
	    auto SoundDef = Cast<USoundDefBase>(Handler);
        if (SoundDef != nullptr)
        {
            return  SoundDef.HazeOwner.Class.Name.ToString();
        }
		devCheck(false, "Could not cast event handler to extract VoiceOverIDClassName.");
        return "Undefined";
    }

	// Get class string and ID number (the combination is unique)
    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
    FString GetVoiceIdString(UObject Handler)
    {
		// Called from BP derived class
		auto Owner = Cast<ABasicAICharacter>(Handler);
        if (Owner != nullptr)
		{
			return Owner.Class.Name.ToString() + "__" + UBasicAIVoiceOverComponent::Get(Owner).GetVoiceOverID();
		}

		// Called from EBP
        auto EventHandler = Cast<UHazeEffectEventHandler>(Handler);
        if (EventHandler != nullptr)
        {
            return EventHandler.Owner.Class.Name.ToString() + "__" + UBasicAIVoiceOverComponent::Get(EventHandler.Owner).GetVoiceOverID();
        }
		
		// Called from SoundDef
        auto SoundDef = Cast<USoundDefBase>(Handler);
        if (SoundDef != nullptr)
        {
            return SoundDef.HazeOwner.Class.Name.ToString() + "__" + UBasicAIVoiceOverComponent::Get(SoundDef.HazeOwner).GetVoiceOverID();
        }
        devCheck(false, "Could not cast event handler to extract VoiceOverIDString.");
        return "Undefined";
    }

    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
	AHazeActor GetClosestFriendly(UObject Handler, float MaxRange = 1000000.0)
	{
		AHazeActor Actor = GetHandlerActor(Handler);
		UHazeTeam Team = GetActorTeam(Actor);
		if (Team == nullptr)
			return nullptr;

		FVector OwnLoc = Actor.ActorLocation;
		AHazeActor Closest = nullptr;
		float ClosestDistSqr = Math::Square(MaxRange);
		for (AHazeActor TeamMate : Team.GetMembers())
		{
			if (TeamMate == nullptr)
				continue;
			if (TeamMate == Actor)
				continue;
			float DistSqr = TeamMate.ActorLocation.DistSquared(OwnLoc);
			if (DistSqr > ClosestDistSqr)
				continue;
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(TeamMate);
			if ((HealthComp != nullptr) && HealthComp.IsDying())
				continue;
			Closest = TeamMate;
			ClosestDistSqr = DistSqr;
		}
		return Closest;
	}

    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
	TArray<AHazeActor> GetClosestFriendlies(UObject Handler, float MaxRange = 1000000.0)
	{
		TArray<AHazeActor> Result;
		AHazeActor Actor = GetHandlerActor(Handler);
		UHazeTeam Team = GetActorTeam(Actor);
		if (Team == nullptr)
			return Result;

		FVector OwnLoc = Actor.ActorLocation;
		for (AHazeActor TeamMate : Team.GetMembers())
		{
			if (TeamMate == nullptr)
				continue;
			if (TeamMate == Actor)
				continue;
			if (!TeamMate.ActorLocation.IsWithinDist(OwnLoc, MaxRange))
				continue;
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(TeamMate);
			if ((HealthComp != nullptr) && HealthComp.IsDying())
				continue;
			Result.Add(TeamMate);
		}
		Sort::SortByDistanceToLocation(OwnLoc, Result);
		return Result;
	}

    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
	AHazeActor GetClosestEnemy(UObject Handler, float MaxRange = 1000000.0)
	{
		AHazeActor Actor = GetHandlerActor(Handler);
		TArray<AHazeActor> Enemies;
		GetEnemies(Actor, Enemies);
		FVector OwnLoc = Actor.ActorLocation;
		AHazeActor Closest = nullptr;
		float ClosestDistSqr = Math::Square(MaxRange);
		for (AHazeActor Enemy : Enemies)
		{
			if (Enemy == nullptr)
				continue;
			if (Enemy == Actor)
				continue;
			float DistSqr = Enemy.ActorLocation.DistSquared(OwnLoc);
			if (DistSqr > ClosestDistSqr)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Enemy);
			if (Player != nullptr) 
			{
				if (Player.IsPlayerDead())	
					continue;
			}
			else 
			{
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Enemy);
				if ((HealthComp != nullptr) && HealthComp.IsDying())
					continue;
			}
			Closest = Enemy;
			ClosestDistSqr = DistSqr;
		}
		return Closest;
	}

    UFUNCTION(BlueprintPure, meta = (DefaultToSelf = "Handler"))
	TArray<AHazeActor> GetClosestEnemies(UObject Handler, float MaxRange = 1000000.0)
	{
		TArray<AHazeActor> Result;
		AHazeActor Actor = GetHandlerActor(Handler);
		TArray<AHazeActor> AllEnemies;
		GetEnemies(Actor, AllEnemies);
		FVector OwnLoc = Actor.ActorLocation;
		for (AHazeActor Enemy : AllEnemies)
		{
			if (Enemy == nullptr)
				continue;
			if (Enemy == Actor)
				continue;
			if (!Enemy.ActorLocation.IsWithinDist(OwnLoc, MaxRange))
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Enemy);
			if (Player != nullptr) 
			{
				if (Player.IsPlayerDead())	
					continue;
			}
			else 
			{
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Enemy);
				if ((HealthComp != nullptr) && HealthComp.IsDying())
					continue;
			}
			Result.Add(Enemy);
		}
		Sort::SortByDistanceToLocation(OwnLoc, Result);
		return Result;
	}

	AHazeActor GetHandlerActor(UObject Handler)
	{
		// Called from BP derived class?
		AHazeActor Actor = Cast<AHazeActor>(Handler);
        if (Actor == nullptr)
		{
			// Called from EBP?
			auto EventHandler = Cast<UHazeEffectEventHandler>(Handler);
			if (EventHandler != nullptr)
			{
				Actor = Cast<AHazeActor>(EventHandler.Owner);
			}
			else
			{
				// Called from SoundDef?
				auto SoundDef = Cast<USoundDefBase>(Handler);
				if (SoundDef != nullptr)
					Actor = SoundDef.HazeOwner;
			}
		}
		if (Actor == nullptr)
			return nullptr;
		return Actor;	
	}

	UHazeTeam GetActorTeam(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return nullptr;
		UBasicBehaviourComponent BehaviourComp = UBasicBehaviourComponent::Get(Actor);
		if (BehaviourComp == nullptr)
			return nullptr;
		return BehaviourComp.Team;
	}

	void GetEnemies(AHazeActor Actor, TArray<AHazeActor>& OutEnemies)
	{
		if (Actor == nullptr)
			return;

		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Actor);
		if (TargetComp == nullptr) 
		{
			OutEnemies.Add(Game::Mio);
			OutEnemies.Add(Game::Zoe);
			return;
		}
		TargetComp.GetPotentialTargets(OutEnemies);
	}	
}

