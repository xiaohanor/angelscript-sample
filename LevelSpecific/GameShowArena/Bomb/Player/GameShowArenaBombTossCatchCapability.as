struct FGameShowArenaBombTossCatchActivatedParams
{
	AGameShowArenaBomb ClosestBomb;
}

struct FGameShowArenaBombTossCatchDeactivatedParams
{
	AGameShowArenaBomb CaughtBomb;
}

class UGameShowArenaBombTossCatchCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossCatch");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	default DebugCategory = n"GameShow";

	float CatchDuration = 1;
	float CatchCooldown = 0.5;

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;

	bool bHasCaughtBomb;

	const float InitialCatchSphereRadius = 100;
	const float CatchSphereRadiusGrowthRate = 1000;
	const float CatchSphereRadiusShrinkRate = 1500;

	float VisualCatchSphereRadius = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return false;

		if (BombTossPlayerComponent.bIsInteracting)
			return false;

		if (BombTossPlayerComponent.CurrentBomb != nullptr)
			return false;

		if (Time::GetGameTimeSince(BombTossPlayerComponent.TimeWhenLastTriedToCatch) < CatchCooldown)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= CatchDuration)
			return true;

		if (bHasCaughtBomb)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasCaughtBomb = false;
		VisualCatchSphereRadius = InitialCatchSphereRadius;
		FGameShowArenaTryCatchBombStartedEventParams Params;
		Params.Player = Player;
		Params.MaxCatchRadius = BombTossPlayerComponent.CatchSphereRadius;
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerTryCatchStarted(Player, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BombTossPlayerComponent.TimeWhenLastTriedToCatch = Time::GameTimeSeconds;
		BombTossPlayerComponent.AnimParams.bCatch = false;
		if (!bHasCaughtBomb && BombTossPlayerComponent.bHasIncomingBomb)
		{
			FGameShowArenaBombCatchFailedEventParams Params;
			Params.Player = Player;
			UGameShowArenaBombTossEventHandler::Trigger_OnPlayerBombCatchFailed(Player, Params);
		}
		else if (bHasCaughtBomb)
		{
			BombTossPlayerComponent.bHasIncomingBomb = false;
		}

		FGameShowArenaTryCatchBombStoppedEventParams Params;
		Params.Player = Player;
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerTryCatchStopped(Player, Params);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FGameShowArenaTryCatchBombActiveEventParams Params;
		Params.MaxCatchRadius = BombTossPlayerComponent.CatchSphereRadius;
		Params.Origin = Player.ActorCenterLocation;
		Params.Player = Player;
		UGameShowArenaBombTossEventHandler::Trigger_OnPlayerTryCatchActive(Player, Params);

		if (bHasCaughtBomb)
			return;

		auto ClosestBomb = GameShowArena::GetClosestEnabledBombToLocation(Player.ActorLocation);
		if (ClosestBomb == nullptr)
			return;

		if (!BombTossPlayerComponent.CanCatchBomb(ClosestBomb))
			return;

		if (!HasControl())
			return;

		bool bBombWasFrozen = false;
		if (ClosestBomb.State.Get() == EGameShowArenaBombState::Frozen)
		{
			ClosestBomb.CrumbUnfreeze();
			bBombWasFrozen = true;
		}

		CrumbCatchBomb(ClosestBomb, bBombWasFrozen);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCatchBomb(AGameShowArenaBomb Bomb, bool bBombWasFrozen)
	{
		BombTossPlayerComponent.AssignBomb(Bomb);
		BombTossPlayerComponent.AnimParams.bCatch = true;
		bHasCaughtBomb = true;
		BombTossPlayerComponent.TimeWhenCaughtBomb = Time::GameTimeSeconds;
		BombTossPlayerComponent.OnPlayerCaughtBomb.Broadcast(Player, Bomb);
		if (HasControl())
		{
			Bomb.CrumbCatch(Player);
			Bomb.NetCatchBomb(Bomb.ActorLocation);
		}

		Player.PlayForceFeedback(BombTossPlayerComponent.CatchFF, false, false, this);

		if (bBombWasFrozen)
		{
			FGameShowArenaBombPickedUpParams EventParams;
			EventParams.Player = Player;
			EventParams.Bomb = Bomb;
			UGameShowArenaBombTossEventHandler::Trigger_OnPlayerPickedUpBomb(Player, EventParams);
		}
		else
		{
			FGameShowArenaBombCaughtEventParams Params;
			Params.Bomb = Bomb;
			Params.Player = Player;
			UGameShowArenaBombTossEventHandler::Trigger_OnPlayerCaughtBomb(Player, Params);
		}
	}
}