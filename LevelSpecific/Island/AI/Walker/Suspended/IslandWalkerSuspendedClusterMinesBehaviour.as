struct FWalkerClusterMineTargetData
{
	TArray<FWalkerArenaLanePosition> LaneDestinations;
}

class UIslandWalkerSuspendedClusterMinesBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerSettings Settings;
	TArray<UIslandWalkerClusterMineLauncherComponent> Launchers;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;

	TArray<float> LaunchTimes;
	int SalvoCount;
	int NumLaunched;
	int NumToLaunch;
	float StartLaunchingTime;
	float StopLaunchingTime;

	FVector HoistLoc;

	TPerPlayer<UTargetTrailComponent> TrailComps;
	TPerPlayer<FWalkerClusterMineTargetData> TargetData; 

	float PreviousYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner); 

		for (AHazePlayerCharacter Player : Game::Players)
		{
			TrailComps[Player] = UTargetTrailComponent::GetOrCreate(Player);
		}

		TArray<UIslandWalkerClusterMineLauncherComponent> UnorderedLaunchers;
		Owner.GetComponentsByClass(UnorderedLaunchers);
		Launchers.SetNum(UnorderedLaunchers.Num());
		for (int i = 0; i < UnorderedLaunchers.Num(); i++)
		{
			int LauncherOrder = MapLauncherOrder(UnorderedLaunchers[i].Index);
			Launchers[LauncherOrder] = UnorderedLaunchers[i];
		}
		if (ensure(Launchers.Num() > 0))
		{
			// Since mines are networked, we need to pre-spawn and reserve them
			// Note that even though we detonate active mines when restarting this behaviour, they will linger a 
			// a while for effects to play out. Thus we need a double load of mines prepared.
			int MaxMinesPerLauncher = 2 * Math::CeilToInt(Game::Players.Num() * Settings.ClusterMinesPerPlayer / float(Launchers.Num()));
			for (UIslandWalkerClusterMineLauncherComponent Launcher : Launchers)
			{
				Launcher.PrepareProjectiles(MaxMinesPerLauncher);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Time::GetGameTimeSince(WalkerComp.SuspendIntroCompleteTime) < 2.0)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.ClusterMinesTelegraphDuration + Settings.ClusterMinesAttackDuration + Settings.ClusterMinesRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		DetonateLingeringMines();

		// Hoist into attack position...	
		HoistLoc = GetHoistLocation();
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Medium, this);

		// ...then start launching mines
		NumToLaunch = Game::Players.Num() * Settings.ClusterMinesPerPlayer;
		NumLaunched = 0;
		PopulateLaunchData(NumToLaunch);
		SalvoCount = Math::IntegerDivisionTrunc(NumToLaunch, Launchers.Num());
		if ((NumToLaunch % Launchers.Num()) > 0)
			SalvoCount++;

		PreviousYaw = Owner.ActorRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if (ActiveDuration > Settings.ClusterMinesTelegraphDuration)
			Cooldown.Set(Settings.ClusterMinesAttackCooldown);	
		
		WalkerComp.ArenaLimits.EnableAllRespawnPoints(this);		
	}

	FVector GetHoistLocation()
	{
		FVector Center = WalkerComp.ArenaLimits.ActorLocation;
		FVector OwnLoc = Owner.ActorLocation;
		FVector Loc = Center;
		FVector Fwd = WalkerComp.ArenaLimits.ActorForwardVector; 
		Loc += Fwd * Settings.ClusterMinesHoistOffset.X * ((Fwd.DotProduct(OwnLoc - Center) > 0.0) ? 1.0 : -1.0); 
		FVector Right = WalkerComp.ArenaLimits.ActorRightVector; 
		Loc += Right * Settings.ClusterMinesHoistOffset.Y * ((Right.DotProduct(OwnLoc - Center) > 0.0) ? 1.0 : -1.0); 
		Loc.Z = WalkerComp.ArenaLimits.Height + Settings.ClusterMinesHoistOffset.Z;
		return Loc;		
	}

	void PopulateLaunchData(int NumMines)
	{
		StartLaunchingTime = Settings.ClusterMinesTelegraphDuration;

		UAnimSequence LaunchAnim = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Spawning);
		TArray<float32> SpawnTimes;
		LaunchAnim.GetAnimNotifyTriggerTimes(UWalkerSpawnAnimNotify, SpawnTimes);
		LaunchTimes.SetNum(SpawnTimes.Num());
		for (int i = 0; i < SpawnTimes.Num(); i++)
		{
			LaunchTimes[i] = SpawnTimes[i] + Settings.ClusterMinesTelegraphDuration;
		}
		if (!ensure(LaunchTimes.Num() > 0))
			LaunchTimes.Add(Settings.ClusterMinesTelegraphDuration + 0.5);

		// Double up on launch times (with some extra interval) until we have enough
		float32 ExtraInterval = 0.2;
		while (LaunchTimes.Num() < NumMines)
		{
			int PrevNum = LaunchTimes.Num();
			LaunchTimes.SetNum(LaunchTimes.Num() * 2);
			for (int i = PrevNum - 1; i >= 0; i--)
			{
				LaunchTimes[i * 2] = LaunchTimes[i];
				LaunchTimes[(i * 2) + 1] = LaunchTimes[i] + ExtraInterval;
			}		
			ExtraInterval *= 0.5;
		}

		StopLaunchingTime = StartLaunchingTime + LaunchAnim.PlayLength;
	}

	int MapLauncherOrder(int Index)
	{
		// Hard code order to 5,2,4,1,3,0 (which is current order in animation)
		switch (Index)
		{
			case 0: return 5;
			case 1: return 3;
			case 2: return 1;
			case 3: return 4;
			case 4: return 2;
			case 5: return 0;
		}
		return -1;
	}

	void PopulateTargetData(AHazePlayerCharacter Player, FWalkerClusterMineTargetData& Data)
	{
		FVector PlayerLoc = Player.ActorLocation;
		FVector OuterStart;
		FVector OuterEnd;
		WalkerComp.ArenaLimits.GetInnerEdge(PlayerLoc + TrailComps[Player].GetAverageVelocity(0.5) * 0.5, OuterStart, OuterEnd, Settings.ClusterMineOutsidePoolRange);
		FVector Dir = (OuterStart - OuterEnd).GetSafeNormal2D();
		if (Dir.DotProduct(Player.ViewRotation.ForwardVector) < 0.0)
			Dir *= -1.0;

		FVector OuterCenter = (OuterStart + OuterEnd) * 0.5;
		FVector LateralDir = (WalkerComp.ArenaLimits.GetLocationAlongInnerEdge(OuterCenter) - OuterCenter).GetSafeNormal2D(); 

		FVector BaseLoc = Math::ProjectPositionOnInfiniteLine(OuterStart, Dir, PlayerLoc);
		float MaxScatter = Settings.ClusterMineDispersionInterval * Settings.ClusterMineScatterFactor;
		int MinesPerRow = Math::TruncToInt((Settings.ClusterMineOutsidePoolRange - MaxScatter) / Settings.ClusterMineDispersionInterval) + 1;
		Data.LaneDestinations.Empty(Settings.ClusterMinesPerPlayer);
		for (int iRow = 0; Data.LaneDestinations.Num() < Settings.ClusterMinesPerPlayer; iRow++)
		{
			FVector RowBase = BaseLoc + Dir * Settings.ClusterMineDispersionInterval * (iRow - 1.0);
			for (int iColumn = 0; (iColumn < MinesPerRow) && (Data.LaneDestinations.Num() < Settings.ClusterMinesPerPlayer); iColumn++)
			{
				if (Math::RandRange(0.0, 1.0) < Settings.ClusterMinePatternHoleChance)
					continue;
				FVector Dest = RowBase + LateralDir * Settings.ClusterMineDispersionInterval * iColumn; 
				Dest += LateralDir * Math::RandRange(-1.0, 1.0) * Settings.ClusterMineDispersionInterval * 0.5; // Lateral scatter
				Dest += Dir * Math::RandRange(-1.0, 1.0) * Settings.ClusterMineDispersionInterval * 0.5; // Medial scatter
				Data.LaneDestinations.Add(WalkerComp.ArenaLimits.GetLanePosition(Dest));
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTargetData(AHazePlayerCharacter Player, FWalkerClusterMineTargetData Data)
	{
		TargetData[Player] = Data;
		WalkerComp.ArenaLimits.DisableRespawnPointsAtSide(WalkerComp.ArenaLimits.GetLaneWorldLocation(Data.LaneDestinations.Last()), this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Settings.ClusterMinesTelegraphDuration + Settings.ClusterMinesAttackDuration)
		{
			// Align with arena right and hoist us up
			FVector Dir = WalkerComp.ArenaLimits.ActorRightVector;
			if (Owner.ActorForwardVector.DotProduct(Dir) < 0.0)
				Dir *= -1.0;
			DestinationComp.RotateInDirection(Dir);
			DestinationComp.MoveTowardsIgnorePathfinding(HoistLoc, Settings.SuspendAcceleration);
			WalkerComp.MoveCables(HoistLoc, HoistLoc + Dir * 2000.0, Settings.ClusterMinesTelegraphDuration);
		}
		else
		{
			// Move back towards center of arena
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target);
			FVector SuspendLoc = HoistLoc * 0.5 + WalkerComp.ArenaLimits.ActorLocation * 0.5;
			SuspendLoc.Z = WalkerComp.ArenaLimits.Height + Settings.SuspendHeight - 200.0;
			DestinationComp.MoveTowardsIgnorePathfinding(SuspendLoc, Settings.SuspendAcceleration);

			FVector FocusLoc = SuspendLoc + Owner.ActorForwardVector * 4000.0;
			if (TargetComp.HasValidTarget())
			{
				// Rotate ahead, but not too far from actor forward since cables should never slide in opposite direction from walker turn
				FVector TargetDir = (TargetComp.Target.ActorLocation - SuspendLoc).GetSafeNormal2D();
				if (Owner.ActorForwardVector.DotProduct(TargetDir) > 0.707)
					FocusLoc = SuspendLoc + TargetDir * 4000.0;
				else
					FocusLoc = SuspendLoc + Owner.ActorForwardVector.RotateAngleAxis(Math::Sign(FRotator::NormalizeAxis(Owner.ActorRotation.Yaw - PreviousYaw)) * 60.0, FVector::UpVector) * 4000.0;
			}
			WalkerComp.MoveCables(SuspendLoc, FocusLoc, Settings.ClusterMinesTelegraphDuration);
		}

		if (ActiveDuration > StartLaunchingTime)
		{
			StartLaunchingTime = BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Spawning, EBasicBehaviourPriority::Medium, this);

			UIslandWalkerEffectHandler::Trigger_OnClusterMineTelegraph(Owner);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (Player.HasControl())
				{
					PopulateTargetData(Player, TargetData[Player]);
					CrumbSetTargetData(Player, TargetData[Player]);
				}
			}
		}

		if (ActiveDuration > StopLaunchingTime)
		{
			StopLaunchingTime = BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Medium, this);
		}

		if ((NumLaunched < NumToLaunch) && (ActiveDuration > LaunchTimes[NumLaunched])) 
		{
			int LauncherIndex = Math::IntegerDivisionTrunc(NumLaunched, SalvoCount);
			UIslandWalkerClusterMineLauncherComponent Launcher = Launchers[LauncherIndex];
			UIslandWalkerEffectHandler::Trigger_OnClusterMineLaunch(Owner);
			AHazePlayerCharacter Target = Game::Players[NumLaunched % Game::Players.Num()];
			int PlayerMineIndex = Math::IntegerDivisionTrunc(NumLaunched, Game::Players.Num());
			if (TargetData[Target].LaneDestinations.IsValidIndex(PlayerMineIndex)) 
			{
				// We have target data for this launch
				UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.ForwardVector * Settings.ClusterMineLaunchSpeed);	
				Cast<AIslandWalkerClusterMine>(Projectile.Owner).LaunchAt(Target, TargetData[Target].LaneDestinations[PlayerMineIndex]);	
				NumLaunched++;
			}
		}

		PreviousYaw = Owner.ActorRotation.Yaw;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
		}
#endif		
	}

	void DetonateLingeringMines()
	{
		int NumActiveMines = 0;
		for (UIslandWalkerClusterMineLauncherComponent Launcher : Launchers)
		{
			NumActiveMines += Launcher.ActiveProjectiles.Num();
		}
		if (NumActiveMines > 0)
		{
			// This is deterministic enough not to have to network; interval may differ slightly due to players shooting mines but explosions are networked
			float ExplodeTime = Time::GameTimeSeconds;
			float ExplodeInterval = Settings.ClusterMinesTelegraphDuration / float(NumActiveMines);
			for (UIslandWalkerClusterMineLauncherComponent Launcher : Launchers)
			{
				for (AHazeActor ActiveMine : Launcher.ActiveProjectiles)
				{
					Cast<AIslandWalkerClusterMine>(ActiveMine).ExplodeTime = ExplodeTime;
					ExplodeTime += ExplodeInterval;
				}
			}
		}
	}
}
