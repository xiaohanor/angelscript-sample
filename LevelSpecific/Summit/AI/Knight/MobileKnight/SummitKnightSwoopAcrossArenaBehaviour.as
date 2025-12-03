struct FKnightSwoopAcrossArenaParams
{
	UScenepointComponent Destination;
	int MetalObstacleVariant;
	int CrystalObstacleVariant;
}

class USummitKnightSwoopAcrossArenaBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightStageComponent StageComp;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightSettings Settings;

	UScenepointComponent SwoopDestination;
	float TelegraphDuration;
	float TraversalDuration;
	float RecoveryDuration;
	float SwoopTargetSpeed;
	FHazeAcceleratedFloat SwoopSpeed;
	bool bTraversing = false;
	bool bRecovering = false;
	TArray<AHazePlayerCharacter> AvailableTargets;
	FVector PrevLocation;

	bool bSpawnObstacles = false;
	int NumSpawnedObstacles;
	FAreaDenialZoneObstacleSpawnParameters ObstacleParams;

	USummitKnightSwoopAcrossArenaBehaviour(bool bObstacles)
	{
		bSpawnObstacles = bObstacles;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StageComp = USummitKnightStageComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);

		// Randomize starting obstacle variants. This is replicated along with other obstacle spawn params.
		ObstacleParams.MetalVariant = Math::RandRange(0, 5);
		ObstacleParams.CrystalVariant = Math::RandRange(0, 5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FKnightSwoopAcrossArenaParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		OutParams.Destination = GetBestSwoopDestination();
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > TelegraphDuration + TraversalDuration + RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FKnightSwoopAcrossArenaParams Params)
	{
		Super::OnActivated();
		SwoopDestination = Params.Destination;
		KnightComp.bCanBeStunned.Apply(false, this);

		TelegraphDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::Swoop, SummitKnightSubTagsSwoop::Enter, Settings.SwoopTelegraphDuration);
		TraversalDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::Swoop, SummitKnightSubTagsSwoop::Mh, Settings.SwoopTraversalDuration);
		RecoveryDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::Swoop, SummitKnightSubTagsSwoop::Exit, Settings.SwoopRecoveryDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::Swoop, SummitKnightSubTagsSwoop::Enter, EBasicBehaviourPriority::Medium, this, TelegraphDuration);
		bTraversing = false;
		bRecovering = false;

		SwoopTargetSpeed = Owner.ActorLocation.Dist2D(SwoopDestination.WorldLocation) / Math::Max(0.2, TraversalDuration);
		SwoopSpeed.SnapTo(0.0);

		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();

		CrystalBottom.Retract(this);

		// Always be ready to hit rolling dragon after swoop
		TargetComp.SetTargetLocal(Game::Zoe);

		AvailableTargets = Game::Players;

		ObstacleParams.Reset(Settings.SwoopNumObstacles);
		ObstacleParams.SpawnTime = BIG_NUMBER;
		NumSpawnedObstacles = 0;

		USummitKnightSettings::SetRotationDuration(Owner, TelegraphDuration * 2.0, this);

		USummitKnightEventHandler::Trigger_OnSwoopTelegraph(Owner, FSummitKnightPlayerParams(GetAccidentalTarget()));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);

		// Never swoop twice in succession
		Cooldown.Set(0.5);

		KnightComp.NumberOfSwoops++;
		KnightComp.LastSwoopEndTime = Time::GameTimeSeconds;

		Owner.ClearSettingsByInstigator(this);

		// Spawn any remaining obstacles (unlikely but might happen on remote or due to interrupting behaviour)
		for (int i = NumSpawnedObstacles; i < ObstacleParams.Zones.Num(); i++)
		{
			SpawnObstacle();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bTraversing && (ActiveDuration > TelegraphDuration))
		{
			bTraversing = true;
			AnimComp.RequestSubFeature(SummitKnightSubTagsSwoop::Mh, this, TraversalDuration);
			PrevLocation = Owner.ActorLocation;
			USummitKnightEventHandler::Trigger_OnSwoopChargeStart(Owner, FSummitKnightPlayerParams(GetAccidentalTarget()));
		}
		if (!bRecovering && (ActiveDuration > TelegraphDuration + TraversalDuration) && HasControl())
			CrumbEndSwoop(GetObstacleSpawnParameters());

		// Move to destination, then stop
		if (bTraversing)
		{
			// Swoop!
			SwoopSpeed.AccelerateTo(SwoopTargetSpeed, TraversalDuration * 0.2, DeltaTime);
			if (!SwoopDestination.WorldLocation.IsWithinDist2D(Owner.ActorLocation, 200.0))
				DestinationComp.MoveTowardsIgnorePathfinding(SwoopDestination.WorldLocation, SwoopSpeed.Value);
		}
		else if (bRecovering)
		{
			// Stop
			SwoopSpeed.AccelerateTo(0.0, RecoveryDuration * 0.25, DeltaTime);
			if (!SwoopDestination.WorldLocation.IsWithinDist2D(Owner.ActorLocation, 200.0))
				DestinationComp.MoveTowardsIgnorePathfinding(SwoopDestination.WorldLocation, SwoopSpeed.Value);	
		}

		// Turn towards destination, then target (or arena center if there is no target)
		if (!bRecovering)
		{
			if (!SwoopDestination.WorldLocation.IsWithinDist2D(Owner.ActorLocation, 500.0))
				DestinationComp.RotateTowards(SwoopDestination.WorldLocation);
		}
		else if (ActiveDuration > TelegraphDuration + TraversalDuration + RecoveryDuration * 0.1)
		{
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target);
			else 	
				DestinationComp.RotateTowards(KnightComp.Arena.ActorLocation);
		}

		if (!CrystalBottom.bDeployed && bRecovering && Owner.ActorVelocity.IsNearlyZero(50.0))
			CrystalBottom.Deploy(this);

		if (bTraversing)
		{
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				if (ShouldHitPlayer(AvailableTargets[i]))
					CrumbHitPlayer(AvailableTargets[i]);
			}
		}

		if (ActiveDuration > ObstacleParams.SpawnTime)
			SpawnObstacle();

		PrevLocation = Owner.ActorLocation;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (bTraversing)
				Debug::DrawDebugCircle(Owner.ActorLocation, Settings.SwoopHitPlayerRadius, 12, FLinearColor::Red, 20.0);
		}
#endif		
	}

	bool ShouldHitPlayer(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return false;

		if (Owner.ActorVelocity.IsNearlyZero(500.0))
			return false;

		if (Player.ActorLocation.Z < Owner.ActorLocation.Z - 200.0)
			return false;	
		if (Player.ActorLocation.Z > Owner.ActorLocation.Z + 2000.0)
			return false;	

		FVector ProjectedLoc;
		float Dummy;
		Math::ProjectPositionOnLineSegment(PrevLocation, Owner.ActorLocation, Player.ActorLocation, ProjectedLoc, Dummy);
		if (!ProjectedLoc.IsWithinDist2D(Player.ActorLocation, Settings.SwoopHitPlayerRadius))
			return false;
		return true;
	}

	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		AvailableTargets.RemoveSingleSwap(Player);

		Player.DealTypedDamage(Owner, Settings.SwoopHitPlayerDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, true);		

		FVector StumbleDir = Owner.ActorVelocity.GetSafeNormal2D().CrossProduct(FVector::UpVector);
		if (StumbleDir.DotProduct(Player.ActorLocation - Owner.ActorLocation) < 0.0)
			StumbleDir *= -1.0;
		FVector StumbleMove = StumbleDir * Settings.SwoopHitPlayerStumbleDistance;
		if (!KnightComp.Arena.IsInsideArena(Player.ActorLocation + StumbleMove))
		{
			// Try not to stumble off arena unless very close to edge
			StumbleMove =  KnightComp.Arena.GetClampedToArena(Player.ActorLocation + StumbleMove, 200.0) - Player.ActorLocation;
			StumbleMove.Z = 0.0;
			if (StumbleMove.Size() < 500.0)
				StumbleMove = StumbleMove.GetSafeNormal2D() * 500.0;
		}
		KnightComp.StumbleDragon(Player, StumbleMove, 0.0, 0.8);

		USummitKnightEventHandler::Trigger_OnSwoopHitPlayer(Owner, FSummitKnightPlayerParams(Player));		
	}


	UFUNCTION(CrumbFunction)
	void CrumbEndSwoop(FAreaDenialZoneObstacleSpawnParameters ObstacleParameters)
	{
		bRecovering = true;
		ObstacleParams = ObstacleParameters;
		ObstacleParams.SpawnTime += ActiveDuration;
		NumSpawnedObstacles = 0;

		AnimComp.RequestSubFeature(SummitKnightSubTagsSwoop::Exit, this, RecoveryDuration);
		USummitKnightSettings::SetRotationDuration(Owner, RecoveryDuration, this);
		USummitKnightEventHandler::Trigger_OnSwoopChargeEnd(Owner);
	}

	UScenepointComponent GetBestSwoopDestination() const
	{
		// Get destination furthest from Zoe and far enough away from current location
		UScenepointComponent Best = KnightComp.Arena.SwoopDestination0;
		float BestDistSqr = 0.0;
		for (UScenepointComponent Dest : KnightComp.Arena.SwoopDestinations)
		{
			if (Owner.ActorLocation.IsWithinDist2D(Dest.WorldLocation, KnightComp.Arena.Radius * 0.75))
				continue; // Too close
			float DistSqr = Dest.WorldLocation.DistSquared2D(Game::Zoe.ActorLocation);
			if (DistSqr < BestDistSqr)
				continue;
			Best = Dest;
			BestDistSqr = DistSqr;
		}
		return Best;
	}

	FAreaDenialZoneObstacleSpawnParameters GetObstacleSpawnParameters() const
	{
		FAreaDenialZoneObstacleSpawnParameters Params;
		if (!bSpawnObstacles)
		{
			Params.SpawnTime = BIG_NUMBER;
			return Params;
		}
	
		FindObstacleZones(Params.Zones);
		SortObstacleZones(Params.Zones);

		if (Params.Zones.Num() == 0)
		{
			Params.Reset(Settings.SwoopNumObstacles);
		}
		else
		{
			Params.SpawnTime = RecoveryDuration * 0.5; 
			float SpawnDuration = RecoveryDuration * 0.25;
			UAnimSequence ExitAnim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::Swoop, SummitKnightSubTagsSwoop::Exit);
			TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo;
			if (ensure(ExitAnim != nullptr) && ExitAnim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo) && (ActionInfo.Num() > 0))
			{
				Params.SpawnTime = ActionInfo[0].TriggerTime;
				SpawnDuration = ActionInfo[0].Duration;
			}

			Params.SpawnInterval = SpawnDuration / Math::Max(1.0, float(Params.Zones.Num() - 1));

			// Variants are randomized on setup and then incremented. This ensures they get replicated to remote.
			Params.MetalVariant = ObstacleParams.MetalVariant;
			Params.CrystalVariant = ObstacleParams.CrystalVariant;
		}

		return Params;
	}	

	void FindObstacleZones(TArray<ASummitKnightAreaDenialZone>& OutZones) const
	{
		// Find all zones which are potential obstacle candidates
		FVector OwnLoc = Owner.ActorLocation;
		TArray<ASummitKnightAreaDenialZone> Candidates;
		for (ASummitKnightAreaDenialZone Zone : TListedActors<ASummitKnightAreaDenialZone>())
		{
			if (Zone.HasActiveObstacle())
				continue; // Already in use
			if (Zone.ActorLocation.IsWithinDist2D(OwnLoc, Settings.SwoopObstacleMinRange))
				continue; // Too near
			if (!KnightComp.Arena.IsInsideArena(Zone.ActorLocation, Settings.SwoopObstacleArenaEdgeClearance))
				continue; // Too near arena edge
			Candidates.Add(Zone);
		}
		Candidates.Shuffle();
		
		// Find enough nearby zones to form a blockade
		float Interval = (Settings.SwoopObstacleMaxRange - Settings.SwoopObstacleMinRange) * 0.33;
		for (float Range = Settings.SwoopObstacleMinRange + Interval; Range < Settings.SwoopObstacleMaxRange + 0.1; Range += Interval)
		{
			for (int i = Candidates.Num() - 1; i >= 0; i--)
			{
				if (!Candidates[i].ActorLocation.IsWithinDist2D(OwnLoc, Range))
					continue;
				// Found a zone near enough
				OutZones.Add(Candidates[i]);
				Candidates.RemoveAtSwap(i);
				if (OutZones.Num() >= Settings.SwoopNumObstacles)
					return; // Founc enough zones!
			}
		}
		// If we get here we did not get enough zones, but might still have some
	}

	void SortObstacleZones(TArray<ASummitKnightAreaDenialZone>& InOutZones) const
	{
		// Sort zones on nearness to arena center
		for (ASummitKnightAreaDenialZone Zone : InOutZones)
		{
			Zone.SortScore = Zone.ActorLocation.DistSquared2D(KnightComp.Arena.Center);
		}
		// Ascending order
		InOutZones.Sort(false);
	}

	void SpawnObstacle()
	{
		if (ensure(ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles)))
		{
			// Start with metal obstacles as they hinder tail dragon, then alternate
			if (NumSpawnedObstacles % 2 == 0)
			{
				ObstacleParams.Zones[NumSpawnedObstacles].MetalObstacle.SpawnObstacle(ObstacleParams.MetalVariant, Owner);
				ObstacleParams.MetalVariant++;
			}
			else
			{
				ObstacleParams.Zones[NumSpawnedObstacles].CrystalObstacle.SpawnObstacle(ObstacleParams.CrystalVariant);
				ObstacleParams.CrystalVariant++;
			}
		}

		NumSpawnedObstacles++;
		if (ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles))
			ObstacleParams.SpawnTime += ObstacleParams.SpawnInterval;
		else
			ObstacleParams.SpawnTime = BIG_NUMBER;
	}

	AHazePlayerCharacter GetAccidentalTarget() const
	{
		AHazePlayerCharacter BestPlayer = nullptr;
		float BestScore = Math::Square(Settings.SwoopAccidentalTargetForVOStartRadius);
		FVector Start = Owner.ActorLocation + (SwoopDestination.WorldLocation - Owner.ActorLocation).GetSafeNormal2D() * Settings.SwoopAccidentalTargetForVOStartRadius;
		float EndWidthFactor = (Settings.SwoopAccidentalTargetForVOEndRadius / Settings.SwoopAccidentalTargetForVOStartRadius) - 1.0; 
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float LineFraction = 0.0;
			FVector LineLoc;
			Math::ProjectPositionOnLineSegment(Start, SwoopDestination.WorldLocation, Player.ActorLocation, LineLoc, LineFraction);
			float Score = Player.ActorLocation.DistSquared2D(LineLoc) / Math::Square(1.0 + LineFraction * EndWidthFactor);
			if (Score > BestScore)
				continue;
			BestPlayer = Player;
			BestScore = Score;
		}
		return BestPlayer;
	}
}

