struct FSandSharkChaseStateActivateParams
{
	AHazePlayerCharacter ClosestPlayer;
} struct FSandSharkChaseStateDeactivateParams
{
	ASandSharkSpline NewTargetSpline;
} class USandSharkChaseStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkChase);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = SandShark::TickGroupOrder::Chase;
	default TickGroupSubPlacement = 0;

	ASandShark SandShark;
	USandSharkChaseComponent ChaseComp;
	USandSharkSettings SharkSettings;
	USandSharkMovementComponent MoveComp;

	TPerPlayer<float> PlayerTimesWhenLeftSand;
	TPerPlayer<float> PlayerTimesWhenEnteredSand;
	TArray<AHazePlayerCharacter> PlayersPreviouslyOnSand;

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("MioTimeLeftSand", PlayerTimesWhenLeftSand[Game::Mio])
			.Value("ZoeTimeLeftSand", PlayerTimesWhenLeftSand[Game::Zoe])
			.Value("CanChangeTarget", Time::GetGameTimeSince(PlayerTimesWhenLeftSand[SandShark.GetTargetPlayer()]) > SandShark::Chase::ChangeTargetDelay);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);

		ChaseComp = USandSharkChaseComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSandSharkChaseStateActivateParams& Params) const
	{
		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return false;

		if (!SandShark::IsAnyPlayerOnSand())
			return false;

		auto ClosestPlayer = SandShark::GetClosestPlayerOnSand(SandShark.ActorLocation);

		// if (Time::GetGameTimeSince(SandShark.TimeWhenChasedTarget[ClosestPlayer]) < 0.5)	
		// 	ClosestPlayer = ClosestPlayer.OtherPlayer;

		if (!SandShark.CheckPlayerInsideTerritory(ClosestPlayer))
			return false;

		if (!IsPlayerReachable(ClosestPlayer))
			return false;

		auto SandLocation = Desert::GetLandscapeLocation(ClosestPlayer.ActorLocation);

		FVector NearestLocation;
		bool bCanNavigateToPlayer = Pathfinding::FindNavmeshLocation(SandLocation, SandShark::Navigation::AgentRadius, SandShark::Navigation::AgentHeight, NearestLocation);
		if (!bCanNavigateToPlayer)
			return false;

		if (SandShark.bIsDistractedByGroundPounder)
		{
			// Debug::DrawDebugSphere(SandShark.ActorLocation, SandShark::ThumperChaseIgnoreDistance);
			if (ClosestPlayer.GetDistanceTo(SandShark) > SandShark::PreferPlayerDistance)
				return false;

			FVector ToClosest = (ClosestPlayer.ActorLocation - SandShark.ActorLocation).ProjectOnToNormal(SandShark.ActorForwardVector);
			float Dot = ToClosest.DotProductNormalized(SandShark.ActorForwardVector);
			// Print(f"{Dot=}", 1);
			if (Dot < 0.4)
				return false;
		}

		Params.ClosestPlayer = ClosestPlayer;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSandSharkChaseStateDeactivateParams& Params) const
	{
		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return true;

		if (SandShark.bIsDistractedByGroundPounder)
		{
			return true;
		}
		if (ChaseComp.State != ESandSharkChaseState::Diving)
		{
			bool bZoeReachable = IsPlayerReachable(Game::Zoe);
			bool bMioReachable = IsPlayerReachable(Game::Mio);
			bool bFoundReachablePlayer = bZoeReachable || bMioReachable;
			if (!bFoundReachablePlayer)
			{
				Params.NewTargetSpline = GetNewTargetSpline();
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSandSharkChaseStateActivateParams Params)
	{
		SandShark.TimeWhenStartedChasing = Time::GameTimeSeconds;
		SandShark.TimeWhenChasedTarget[Params.ClosestPlayer] = Time::GameTimeSeconds;

		ChaseComp.State = ESandSharkChaseState::None;
		ChaseComp.DiveActiveDuration = 0;
		ChaseComp.StartChase();

		SandShark.BlockCapabilities(SandSharkBlockedWhileIn::Chase, this);

		SandShark.SetTargetPlayer(Params.ClosestPlayer);

		USandSharkPlayerComponent::Get(Params.ClosestPlayer).AddHuntedInstigator(SandShark);

		if (HasControl())
			ControlUpdatePlayerSandTimes();

		USandSharkEventHandler::Trigger_OnChaseStarted(SandShark);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSandSharkChaseStateDeactivateParams Params)
	{
		ChaseComp.State = ESandSharkChaseState::None;
		ChaseComp.DiveActiveDuration = 0;
		ChaseComp.EndChase();
		for (auto Player : Game::Players)
			USandSharkPlayerComponent::Get(Player).RemoveHuntedInstigator(SandShark);

		SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::Chase, this);

		USandSharkEventHandler::Trigger_OnChaseStopped(SandShark);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		ControlUpdatePlayerSandTimes();

		AHazePlayerCharacter TargetPlayer = SandShark.GetTargetPlayer();
		AHazePlayerCharacter NewTargetPlayer = nullptr;
		bool bIsPlayerWithinTargetDistance = false;

		if (!IsPlayerReachable(TargetPlayer))
		{
			// If our target is no longer on the sand, but we are still active, the other player must be on the sand.
			auto OtherPlayer = TargetPlayer.OtherPlayer;
			if (IsPlayerReachable(OtherPlayer))
				NewTargetPlayer = TargetPlayer.OtherPlayer;
		}
		else
		{
			// If the closest player is not our current target, check proximity and retarget if close enough
			auto ClosestPlayer = SandShark::GetClosestPlayerOnSand(SandShark.ActorLocation);
			if (ClosestPlayer != nullptr && ClosestPlayer != TargetPlayer)
			{
				bIsPlayerWithinTargetDistance = ClosestPlayer.ActorLocation.Distance(SandShark.ActorLocation) <= SandShark::Chase::RetargetDistance;
				FVector ToClosest = (ClosestPlayer.ActorLocation - SandShark.ActorLocation).ProjectOnToNormal(SandShark.ActorForwardVector);
				float Dot = ToClosest.DotProductNormalized(SandShark.ActorForwardVector);
				// Print(f"{Dot=}", 1);
				if (bIsPlayerWithinTargetDistance && Dot >= 0.4)
					NewTargetPlayer = ClosestPlayer;
			}
		}

		if (NewTargetPlayer != nullptr)
		{
			float TimeSinceLeftSand = Time::GetGameTimeSince(PlayerTimesWhenLeftSand[TargetPlayer]);
			if (bIsPlayerWithinTargetDistance || TimeSinceLeftSand >= SandShark::Chase::ChangeTargetDelay)
				SandShark.CrumbSetTargetPlayer(NewTargetPlayer);
		}
		SandShark.DestinationComp.Update();
		SandShark.DestinationComp.MoveTowards(SandShark.GetTargetPlayerLocationOnLandscapeByLevel(SandShark.LandscapeLevel), 2000);
		//SandShark.MoveToComp.Path.DrawDebugSpline();
	}

	bool IsPlayerReachable(AHazePlayerCharacter Player) const
	{
		auto PlayerComp = USandSharkPlayerComponent::Get(Player);

		if (PlayerComp.bIsPerching)
			return false;

		if (PlayerComp.bIsThumping)
			return false;

		if (PlayerComp.bIsPerformingContextualMove)
			return false;

		auto PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		if (!PlayerComp.bHasTouchedSand && PlayerMoveComp.HasGroundContact())
			return false;

		if (PlayerComp.bOnSafePoint)
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (Player.IsPlayerRespawning())
			return false;

		if (!SandShark.CheckPlayerInsideTerritory(Player))
			return false;

		FVector NearestLocation;
		bool bCanNavigateToPlayer = Pathfinding::FindNavmeshLocation(Desert::GetLandscapeLocationByLevel(Player.ActorLocation, SandShark.LandscapeLevel), SandShark::Navigation::AgentRadius, SandShark::Navigation::AgentHeight, NearestLocation);
		if (!bCanNavigateToPlayer)
			return false;

		return true;
	}

	void ControlUpdatePlayerSandTimes()
	{
		check(HasControl());
		auto PlayersOnSand = SandShark::GetPlayersOnSand();
		for (const auto Player : PlayersPreviouslyOnSand)
		{
			if (!PlayersOnSand.Contains(Player))
			{
				PlayerTimesWhenLeftSand[Player] = Time::GetGameTimeSeconds();
			}
		}

		for (const auto Player : PlayersOnSand)
		{
			if (!PlayersPreviouslyOnSand.Contains(Player))
			{
				PlayerTimesWhenEnteredSand[Player] = Time::GetGameTimeSeconds();
			}
		}

		PlayersPreviouslyOnSand = PlayersOnSand;
	}

	ASandSharkSpline GetNewTargetSpline() const
	{
		ASandSharkSpline NewTargetSpline;

		if (SandShark.HasTargetPlayer())
			NewTargetSpline = SandShark.GetTargetPlayerSafePointSpline();

		if (NewTargetSpline == nullptr)
		{
			// If player has not reached a safepoint, use last spline
			NewTargetSpline = SandShark.GetCurrentSpline();
		}
		return NewTargetSpline;
	}
};