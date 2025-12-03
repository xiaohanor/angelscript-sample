struct FGameShowArenaBombTossHoldActivationParams
{
	AGameShowArenaBomb Bomb;
}

class UGameShowArenaBombTossHoldCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossHold");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default BlockExclusionTags.Add(CameraTags::UsableWhileInDebugCamera);

	default DebugCategory = n"GameShow";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 93;

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimingComponent;
	UPlayerInteractionsComponent PlayerInteractionsComp;
	UPlayerTargetablesComponent PlayerTargetables;

	float TimeWhenAimedAtTarget = 0;
	UGameShowArenaBombTargetComponent PreviousTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGameShowArenaBombTossHoldActivationParams& Params) const
	{
		if (BombTossPlayerComponent.CurrentBomb == nullptr)
			return false;

		if (BombTossPlayerComponent.CurrentBomb.IsActorDisabled())
			return false;

		if (BombTossPlayerComponent.CurrentBomb.State.Get() != EGameShowArenaBombState::Held)
			return false;

		Params.Bomb = BombTossPlayerComponent.CurrentBomb;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BombTossPlayerComponent.CurrentBomb == nullptr)
			return true;

		if (BombTossPlayerComponent.CurrentBomb.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGameShowArenaBombTossHoldActivationParams Params)
	{
		Params.Bomb.OnStartHolding.Broadcast(Player);
		BombTossPlayerComponent.bHoldingBomb = true;
		if (HasControl())
		{
			FAimingSettings AimSettings;
			AimSettings.bUseAutoAim = true;
			AimSettings.OverrideAutoAimTarget = UGameShowArenaBombTargetComponent;
			AimSettings.bApplyAimingSensitivity = false;

			PlayerAimingComponent.StartAiming(BombTossPlayerComponent, AimSettings);
			Player.BlockCapabilities(PlayerGrappleTags::GrapplePointQuery, this);
			Player.BlockCapabilitiesExcluding(PlayerMovementTags::WallRun, PlayerMovementTags::WallScramble, this);
			Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
			BombTossPlayerComponent.CurrentBomb.SetActorEnableCollision(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl())
		{
			PlayerAimingComponent.StopAiming(BombTossPlayerComponent);
			Player.UnblockCapabilities(PlayerGrappleTags::GrapplePointQuery, this);
			Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
			Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);

			if (BombTossPlayerComponent.CurrentBomb != nullptr)
			{
				if (BombTossPlayerComponent.CurrentBomb.State.Get() == EGameShowArenaBombState::Exploding || !BombTossPlayerComponent.CurrentBomb.IsActorDisabled())
				{
					BombTossPlayerComponent.RemoveBomb();
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableClass = UGameShowArenaBombTargetComponent;
		WidgetSettings.DefaultWidget = BombTossPlayerComponent.BombTargetableWidget;
		WidgetSettings.MaximumVisibleWidgets = 1;
		WidgetSettings.bOnlyShowWidgetsForPossibleTargets = true;
		if (!Player.IsCapabilityTagBlocked(n"BombTossThrow"))
		{
			PlayerTargetables.ShowWidgetsForTargetables(WidgetSettings);
			if (SceneView::ViewFrustumPointRadiusIntersection(Player, Player.OtherPlayer.ActorLocation, 100, GameShowArenaBombAutoAim::MaximumDistance))
			{
				PreviousTarget = UGameShowArenaBombTargetComponent::Get(Player.OtherPlayer);
				// FAimingOverrideTarget Override;
				// Override.AutoAimTarget = PreviousTarget;
				// PlayerAimingComponent.ApplyAimingTargetOverride(Override, this);
				TimeWhenAimedAtTarget = Time::GameTimeSeconds;
				PreviousTarget.bIsOverrideTarget = true;
			}
			else if (Time::GetGameTimeSince(TimeWhenAimedAtTarget) > 0.35)
			{
				// PlayerAimingComponent.ClearAimingTargetOverride(this);
				if (PreviousTarget != nullptr)
					PreviousTarget.bIsOverrideTarget = false;
			}
		}
	}
}