class ATundraBossRedIceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossRedIceAttack> RedIceActors;

	UPROPERTY(EditInstanceOnly)
	AHazeActor RedIceHeightPhase02;
	UPROPERTY(EditInstanceOnly)
	AHazeActor RedIceHeightPhase03;

	ATundraBoss Boss;
	ATundraBossAttackRestrictionZone CurrentRestrictedZone;

	float RedIceTimerDuration;
	float RedIceTimer = 0;

	bool bShouldTickRedIceTimer = false;
	bool bRedIceActive = false;

	float RedIceHeight;

	int RedIceIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = TundraBossArena::GetTundraBoss();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickRedIceTimer)
			return;

		RedIceTimer += DeltaSeconds;
		if(RedIceTimer >= RedIceTimerDuration)
		{
			RedIceTimer = 0;
			if(!bRedIceActive)
				bShouldTickRedIceTimer = false;
			else
				SpawnRedIce();
		}
	}

	void StartSpawningRedIce(float NewDropInterval, bool bIsLastPhase)
	{
		RedIceTimerDuration = NewDropInterval;

		if(bIsLastPhase)
			RedIceHeight = RedIceHeightPhase03.ActorLocation.Z;
		else
			RedIceHeight = RedIceHeightPhase02.ActorLocation.Z;

		if(!bRedIceActive)
		{
			SpawnRedIce();
			RedIceTimer = 0;
			bShouldTickRedIceTimer = true;
			bRedIceActive = true;
		}
	}

	void SpawnRedIce()
	{
		for(auto Player : Game::GetPlayers())
		{
			if(Player.IsPlayerDead())
				continue;

			if(Player.IsAnyCapabilityActive(n"TundraPlayerTreeGuardianRangedShootCapability"))
				continue;

			if(RedIceIndex > RedIceActors.Num() - 1)
				RedIceIndex = 0;

			const FVector SpawnLocation = GetNewSpawnLocation(Player);
			RedIceActors[RedIceIndex].StartRedIceAttack(SpawnLocation);
			RedIceIndex++;

			if(Boss == nullptr)
				Boss = TryGetBoss();

			UTundraBoss_EffectHandler::Trigger_OnSpawnRedIceAttack(Boss, FTundraBossRedIceAttackData(SpawnLocation));
		}
	}

	void StopRedIce()
	{
		bRedIceActive = false;
	}

	FVector GetNewSpawnLocation(AHazePlayerCharacter Player)
	{
		FVector NewLoc = Player.ActorLocation;
		NewLoc.Z = RedIceHeight;

		if(CurrentRestrictedZone == nullptr)
		{
			return GetRandomOffsetBasedOnPlayerLocation(Player);	
		}
		else
		{
			NewLoc = CurrentRestrictedZone.GetSpawnLocationWithRestriction(Player, 200);
			if(NewLoc == FVector::ZeroVector)
			{
				return GetRandomOffsetBasedOnPlayerLocation(Player);
			}
			else
			{
				NewLoc.Z = RedIceHeight;
				return NewLoc;
			}
		}
	}

	FVector GetRandomOffsetBasedOnPlayerLocation(AHazePlayerCharacter Player)
	{
		FVector NewLoc = Player.ActorLocation;
		
		if(Player.ActorVelocity.Size2D() <= 150)
		{
			NewLoc.Z = RedIceHeight;
			return NewLoc;
		}

		NewLoc += Player.ActorForwardVector * Math::RandRange(150, 750);
		NewLoc += Player.ActorRightVector * Math::RandRange(-200, 200);

		NewLoc.Z = RedIceHeight;
		return NewLoc;
	}

	UFUNCTION()
	void SetNewRedIceRestrictionZone(ATundraBossAttackRestrictionZone NewZone)
	{
		CurrentRestrictedZone = NewZone;
	}

	UFUNCTION()
	void ClearRedIceRestrictionZone()
	{
		CurrentRestrictedZone = nullptr;
	}

	ATundraBoss TryGetBoss()
	{
		if(Boss == nullptr)
			Boss = TundraBossArena::GetTundraBoss();
	
		return Boss;
	}
};