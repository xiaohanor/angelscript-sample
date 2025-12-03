event void FRedSpaceLauncherEvent(AHazePlayerCharacter Player);
event void FRedSpaceLauncherBothPlayersEvent();

UCLASS(Abstract)
class ARedSpaceLauncher : AHazeActor
{
	default bBlockTickOnDisable = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaunchRotOffsetComp;

	UPROPERTY(DefaultComponent, Attach = LaunchRotOffsetComp)
	USceneComponent LauncherRoot;

	UPROPERTY(DefaultComponent, Attach = LauncherRoot)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve LauncherCurve;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY()
	FRedSpaceLauncherEvent OnPlayerLaunched;

	UPROPERTY()
	FRedSpaceLauncherBothPlayersEvent OnBothPlayersLaunched;

	UPROPERTY(EditInstanceOnly)
	AActor MioLaunchTarget;

	UPROPERTY(EditInstanceOnly)
	AActor ZoeLaunchTarget;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	bool bLaunchTriggered = false;
	bool bLaunchLockedIn = false;
	bool bCompletedLaunchCycle = true;

	TPerPlayer<bool> PlayerHasLaunchedLocal;
	TPerPlayer<bool> PlayerLaunchResult;
	TPerPlayer<bool> ReceivedPlayerLaunch;

	float TetherKillDisableTimer = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
		
		URedSpaceLauncherffectEventHandler::Trigger_ActivateLauncher(this);
	}

	UFUNCTION(NetFunction)
	private void NetRemoteStartLaunchCycle()
	{
		if (!HasControl())
			StartLaunchCycle();
	}
	
	UFUNCTION(NetFunction)
	private void NetCompletedLaunchCycle()
	{
		TEMPORAL_LOG(this).Event(f"Completed Launch Cycle");
		bCompletedLaunchCycle = true;
	}

	UFUNCTION()
	private void StartLaunchCycle()
	{
		TEMPORAL_LOG(this).Event(f"Start Launch Cycle");
		ActionQueue.Duration(4.0, this, n"UpdateLaunch");
		ActionQueue.Event(this, n"FinishLaunch");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Add(Player);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Remove(Player);
	}

	UFUNCTION()
	private void UpdateLaunch(float CurValue)
	{
		float Position = LauncherCurve.GetFloatValue(CurValue);
		float Offset = Math::Lerp(0.0, 750.0, Position);
		LauncherRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));

		if (Position >= 0.6 && !bLaunchTriggered)
			LaunchPlayers();
	}

	UFUNCTION()
	private void FinishLaunch()
	{
		bLaunchTriggered = false;
		URedSpaceLauncherffectEventHandler::Trigger_ActivateLauncher(this);

		if (!HasControl() || !Network::IsGameNetworked())
			NetCompletedLaunchCycle();
	}

	void LaunchPlayers()
	{
		if (bLaunchTriggered)
			return;
		if (bLaunchLockedIn)
			return;

		bLaunchTriggered = true;

		for (AHazePlayerCharacter Player : PlayersOnPlatform)
		{
			// LaunchTo does local simulation for responsiveness
			TriggerPlayerLocalLaunch(Player);
		}

		for (AHazePlayerCharacter Player : PlayersOnPlatform)
		{
			// The event only happens when the control player wants to launch however
			if (Player.HasControl())
			{
				DisableTetherKillTemporary(5.0);
				NetPlayerLaunchHandshake(Player, true);
				CrumbPlayerLaunched(Player);
			}

			Player.PlayForceFeedback(LaunchForceFeedback, false, true, this);
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!PlayersOnPlatform.Contains(Player))
			{
				if (Player.HasControl())
					NetPlayerLaunchHandshake(Player, false);
			}
		}
	}

	void TriggerPlayerLocalLaunch(AHazePlayerCharacter Player)
	{
		FPlayerLaunchToParameters LaunchTo;
		LaunchTo.Type = EPlayerLaunchToType::LaunchToPoint;
		LaunchTo.LaunchToLocation = Player.IsMio() ? MioLaunchTarget.ActorLocation : ZoeLaunchTarget.ActorLocation;
		LaunchTo.Duration = 3.0;
		LaunchTo.NetworkMode = EPlayerLaunchToNetworkMode::SimulateLocal;
		Player.LaunchPlayerTo(this, LaunchTo);

		PlayerHasLaunchedLocal[Player] = true;
	}

	UFUNCTION(NetFunction)
	void NetPlayerLaunchHandshake(AHazePlayerCharacter Player, bool bWasLaunched)
	{
		TEMPORAL_LOG(this).Event(f"NetPlayerLaunchHandshake {Player} (Control: {Player.HasControl()}) = {bWasLaunched}");

		ReceivedPlayerLaunch[Player] = true;
		PlayerLaunchResult[Player] = bWasLaunched;

		if (ReceivedPlayerLaunch[Player.OtherPlayer])
		{
			if (bWasLaunched && PlayerLaunchResult[Player.OtherPlayer])
			{
				TEMPORAL_LOG(this).Event(f"Launch Complete");
				OnBothPlayersLaunched.Broadcast();
				bLaunchLockedIn = true;

				// Launch the other player if they aren't already being launched
				if (Network::IsGameNetworked())
				{
					AHazePlayerCharacter RemotePlayer = Game::FirstLocalPlayer.OtherPlayer;
					if (!PlayerHasLaunchedLocal[RemotePlayer])
						TriggerPlayerLocalLaunch(RemotePlayer);
				}
			}
			else
			{
				TEMPORAL_LOG(this).Event(f"Launch Fail");
				ReEnableTetherKill();
			}

			ReceivedPlayerLaunch[Player] = false;
			ReceivedPlayerLaunch[Player.OtherPlayer] = false;

			PlayerHasLaunchedLocal[Player] = false;
			PlayerHasLaunchedLocal[Player.OtherPlayer] = false;
		}
	}

	void DisableTetherKillTemporary(float DisableTime)
	{
		auto TetherActor = TListedActors<ARedSpaceTether>().GetSingle();
		TetherActor.bCanKillPlayers = false;
		TetherKillDisableTimer = DisableTime;
	}

	void ReEnableTetherKill()
	{
		auto TetherActor = TListedActors<ARedSpaceTether>().GetSingle();
		TetherActor.bCanKillPlayers = true;
		TetherKillDisableTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl() && !IsActorDisabled())
		{
			if (ActionQueue.IsEmpty() && bCompletedLaunchCycle)
			{
				bCompletedLaunchCycle = false;
				if (Network::IsGameNetworked())
				{
					Timer::SetTimer(this, n"StartLaunchCycle", Math::Max(Network::PingOneWaySeconds, 0.001));
					NetRemoteStartLaunchCycle();
				}
				else
				{
					StartLaunchCycle();
				}
			}
		}

		if (TetherKillDisableTimer > 0)
		{
			TetherKillDisableTimer -= DeltaSeconds;
			if (TetherKillDisableTimer <= 0)
			{
				auto TetherActor = TListedActors<ARedSpaceTether>().GetSingle();
				TetherActor.bCanKillPlayers = true;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayerLaunched(AHazePlayerCharacter Player)
	{
		OnPlayerLaunched.Broadcast(Player);
	}

	UFUNCTION()
	void ResetPlayerMovement(AHazePlayerCharacter Player)
	{
		Player.ResetMovement();
	}

	UFUNCTION()
	void ClampPlayerVelocity(AHazePlayerCharacter Player)
	{
		Player.SetActorHorizontalVelocity(FVector(1200.0, 0.0, 0.0));
	}
}

class URedSpaceLauncherffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ActivateLauncher() {}
}