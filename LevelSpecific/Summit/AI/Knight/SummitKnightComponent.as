class USummitKnightComponent : UActorComponent
{
	FVector CenterDir;
	FVector StartLoc;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset TailDragonImpactCameraSettings;

	UPROPERTY(EditAnywhere)
	AHazeActorSpawnerBase CritterSpawner; 

	UPROPERTY()
	TSubclassOf<ASummitKnightTorusShockwave> TorusShockWaveClass;
	ASummitKnightTorusShockwave TorusShockWave;

	UPROPERTY(EditAnywhere)
	AActor ArenaFloorRef;

	UPROPERTY(EditInstanceOnly)
	ASummitDragonSlayerAoeManager InitialAoeManager;

	UPROPERTY(EditInstanceOnly)
	ASummitKnightMobileArena Arena;

	AHazeActor ActiveDivider;

	access CrystalTrailsBehaviour = private, USummitKnightCrystalTrailBehaviour;
	access:CrystalTrailsBehaviour bool bSpawningCrystalTrails = false;

	bool IsSpawningCrystalTrails() const { return bSpawningCrystalTrails; }
	TArray<ASummitKnightCrystalTrail> ActiveCrystalTrails;

	TInstigated<bool> bCanBeStunned;
	default bCanBeStunned.DefaultValue = true;
	float LastStunnedTime = -BIG_NUMBER;

	int NumberOfSwoops = 0;
	float LastSwoopEndTime = -BIG_NUMBER;
	TInstigated<bool> bCanDodge;
	default bCanDodge.SetDefaultValue(true);
	TInstigated<bool> bCanDie;
	default bCanDie.SetDefaultValue(false);

	TPerPlayer<bool> bDeathCouldHaveBeenDashAvoided;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CenterDir = Owner.ActorForwardVector;
		StartLoc = Owner.ActorLocation;

		bCanDodge.SetDefaultValue(true);
	}

	void DeactivateSpawners()
	{
		CritterSpawner.DeactivateSpawner();
	}

	FVector GetArenaLocation(FVector Location, AHazePlayerCharacter Target = nullptr)
	{
		if (Arena == nullptr)
		{
			if (ArenaFloorRef == nullptr)
				return Location;
			FVector GroundLoc = Location;
			GroundLoc.Z = ArenaFloorRef.ActorLocation.Z;		
			return GroundLoc;
		}
		return Arena.GetAtArenaHeight(Location);
	}

	float GetArenaHeight(AHazePlayerCharacter Player = nullptr)
	{
		return GetArenaLocation(Owner.ActorLocation, Player).Z;
	}

	FVector GetArenaCenter(float FractionOfArena, AHazePlayerCharacter Target = nullptr)
	{
	 	if (Arena == nullptr)
		{
			FVector Start = GetArenaLocation(Owner.ActorLocation, Target);	
			FVector Dir = (ArenaFloorRef == nullptr) ? Owner.ActorForwardVector : (ArenaFloorRef.ActorLocation - Start).GetSafeNormal2D();
			return Start + Dir * 8000.0 * FractionOfArena;
		}
		return Arena.Center;
	}

	float GetArenaLength(AHazePlayerCharacter Target = nullptr)
	{
		return GetArenaCenter(0.0, Target).Distance(GetArenaCenter(1.0, Target));
	}

	UFUNCTION(BlueprintPure)
	FVector GetSecondPhaseLocation()
	{
		return Arena.SwoopDestination3.WorldLocation;
	}	

	bool StumbleDragon(AHazePlayerCharacter Player, FVector Move, float MinInterval = 1.0, float HeightFactor = 0.2, float ClampWithinArenaThreshold = 0.0)
	{
		if (Move.IsNearlyZero(1.0))
			return false;

		UTeenDragonStumbleComponent StumbleComp = UTeenDragonStumbleComponent::GetOrCreate(Player);		
		if (Time::GetGameTimeSince(StumbleComp.LastStumbleTime) < MinInterval)
			return false;

		FTeenDragonStumble Stumble;
		Stumble.Move = Move;

		if (ClampWithinArenaThreshold > 0.0)
		{
			FVector PlayerArenaLoc = Arena.GetAtArenaHeight(Player.ActorLocation);
			if (Arena.IsInsideArena(PlayerArenaLoc, ClampWithinArenaThreshold * 2.0))
			{
				Stumble.Move = Arena.GetClampedToArena(PlayerArenaLoc + Move, ClampWithinArenaThreshold) - PlayerArenaLoc;
				Stumble.Move.Z = Move.Z;
			}
		}	

		float Distance = Move.Size();
		Stumble.Duration = 0.7;
		Stumble.ArcHeight = Distance * HeightFactor;
		Stumble.Apply(Player);
		return true;
	}

	void SpawnTorusShockWave()
	{
		if (TorusShockWave != nullptr)
			return;
		TorusShockWave = SpawnActor(TorusShockWaveClass, Owner.ActorLocation, Owner.ActorRotation, NAME_None, true, Owner.Level);
		TorusShockWave.MakeNetworked(this, n"TorusShockWave");
		FinishSpawningActor(TorusShockWave);
	}

	UFUNCTION(CrumbFunction)
	void CrumbShockwaveHitPlayerEffect(AHazePlayerCharacter Player, float Damage, FVector DamageDir)
	{
		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = Player; 
		DamageEventParams.Damage = Damage; 
		DamageEventParams.Direction = DamageDir;
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(Cast<AHazeActor>(Owner), DamageEventParams);
	}

	FVector GetSpellFocus() const
	{
		AHazePlayerCharacter PlayerFocus = nullptr;
		if (!Game::Mio.IsPlayerDead())
			PlayerFocus = Game::Mio;
		else if (!Game::Zoe.IsPlayerDead())
			PlayerFocus = Game::Zoe;
		if (PlayerFocus != nullptr)
			return Arena.GetClampedToArena(PlayerFocus.ActorLocation, 1500.0);
		return Arena.Center;
	}
	
	const float ObstacleRadius = 150.0;

	void SmashObstaclesInTeardrop(FVector BaseLoc, FVector TipLoc, float BaseRadius, float TipRadius)
	{
		if (!HasControl())
			return;
		TArray<ASummitKnightAreaDenialZone> Zones = TListedActors<ASummitKnightAreaDenialZone>().Array;
		for (ASummitKnightAreaDenialZone Zone : Zones)
		{
			if (!Zone.HasActiveObstacle())
				continue;
			if (!Zone.ActorLocation.IsInsideTeardrop2D(BaseLoc, TipLoc, BaseRadius + ObstacleRadius, TipRadius + ObstacleRadius))
				continue;
			Zone.CrumbSmashObstacle();
		}		
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeathWhichCouldHaveBeenDashAvoided(AHazePlayerCharacter Player)
	{
		bDeathCouldHaveBeenDashAvoided[Player] = true; 
	}
}
