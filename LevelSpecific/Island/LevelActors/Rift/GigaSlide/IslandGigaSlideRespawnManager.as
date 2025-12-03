event void FIslandGigaSlideRespawnManagerCheckpointEvent(AIslandGigaSlideRespawnVolume CheckpointVolume);

class AIslandGigaSlideRespawnManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("S_Player");

	UPROPERTY(DefaultComponent)
	UIslandGigaSlideRespawnManagerVisualizerComponent VisualizerComp;

	AIslandGigaSlideRespawnVolume CurrentSelectedVolume;
#endif
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	float MinDelayToRespawnOtherPlayer = 1.0;

	UPROPERTY(EditAnywhere)
	float MinDelayToBeDeadBeforeCheckpointRespawning = 1.0;

	UPROPERTY()
	FIslandGigaSlideRespawnManagerCheckpointEvent OnPlayersRespawnAtCheckpoint;

	bool bRespawnSystemActive = false;
	AIslandGigaSlideRespawnVolume CurrentCheckpointVolume;
	TPerPlayer<UPlayerHealthComponent> HealthComps;
	TPerPlayer<bool> bRespawnBlocked;
	bool bStartedDelayedRespawn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			HealthComps[Player] = UPlayerHealthComponent::Get(Player);
		}
	}

	UFUNCTION()
	void ActivateRespawnSystem()
	{
		if(bRespawnSystemActive)
			return;

		BlockRespawnBoth();

		bRespawnSystemActive = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateRespawnSystem(bool bResetStickyRespawnPoints)
	{
		if(!bRespawnSystemActive)
			return;
		
		UnblockRespawnBoth();
		
		bRespawnSystemActive = false;
		CurrentCheckpointVolume = nullptr;
		SetActorTickEnabled(false);

		if(bResetStickyRespawnPoints)
		{
			Game::Mio.ResetStickyRespawnPoints();
			Game::Zoe.ResetStickyRespawnPoints();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bRespawnSystemActive)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!bRespawnBlocked[Player] && !Player.IsPlayerDead())
			{
				BlockRespawnCapabilities(Player);
			}
		}

		if(!HasControl())
			return;

		if(!bStartedDelayedRespawn && CanRespawnAtCheckpoint(Game::Mio) && CanRespawnAtCheckpoint(Game::Zoe))
		{
			if(Network::IsGameNetworked())
			{
				if(!HasControl())
					return;

				for(auto Player : Game::Players)
				{
					if (Player.HasControl())
					{
						Timer::SetTimer(this, n"DelayedRespawnPlayer", Network::PingOneWaySeconds);
						bStartedDelayedRespawn = true;
					}
					else
					{
						NetRespawnPlayer(Player, CurrentCheckpointVolume);
					}
				}
			}
			else
			{
				RespawnBoth(CurrentCheckpointVolume);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRespawnPlayer(AHazePlayerCharacter Player, AIslandGigaSlideRespawnVolume CheckpointVolume)
	{
		if(!Player.HasControl())
			return;

		RespawnPlayer(Player, CheckpointVolume);
	}

	UFUNCTION()
	private void RespawnBoth(AIslandGigaSlideRespawnVolume CheckpointVolume)
	{
		if(CheckpointVolume != nullptr)
			CheckpointVolume.SetStickyForBoth();
		
		OnPlayersRespawnAtCheckpoint.Broadcast(CheckpointVolume);
		UnblockRespawnBoth();
	}

	UFUNCTION()
	private void DelayedRespawnPlayer()
	{
		RespawnPlayer(Game::FirstLocalPlayer, CurrentCheckpointVolume);
		bStartedDelayedRespawn = false;
	}

	private void RespawnPlayer(AHazePlayerCharacter Player, AIslandGigaSlideRespawnVolume CheckpointVolume)
	{
		if(CheckpointVolume != nullptr)
			CheckpointVolume.SetStickyFor(Player);
		
		OnPlayersRespawnAtCheckpoint.Broadcast(CheckpointVolume);
		UnblockRespawnCapabilities(Player);
	}

	bool CanRespawnAtCheckpoint(AHazePlayerCharacter Player) const
	{
		if(!Player.IsPlayerDead())
			return false;

		if(!bRespawnBlocked[Player])
			return false;

		if(Time::GetGameTimeSince(HealthComps[Player].GameTimeOfDeath) < MinDelayToBeDeadBeforeCheckpointRespawning)
			return false;

		return true;
	}

	bool CanRespawnPlayer(AHazePlayerCharacter Player) const
	{
		bool bIsDead = Player.IsPlayerDead();
		devCheck(bIsDead, "Checked if we can respawn the player but the player is not dead!");

		if(Time::GetGameTimeSince(HealthComps[Player].GameTimeOfDeath) < MinDelayToRespawnOtherPlayer)
			return false;

		return true;
	}

	void BlockRespawnBoth()
	{
		BlockRespawnCapabilities(Game::Mio);
		BlockRespawnCapabilities(Game::Zoe);
	}

	void UnblockRespawnBoth()
	{
		UnblockRespawnCapabilities(Game::Mio);
		UnblockRespawnCapabilities(Game::Zoe);
	}

	// Block both players respawn capabilities.
	void BlockRespawnCapabilities(AHazePlayerCharacter Player)
	{
		if(bRespawnBlocked[Player])
			return;

		Player.BlockCapabilities(n"Respawn", this);
		bRespawnBlocked[Player] = true;
	}

	// Unblock both players respawn capabilities and block them again when player is no longer dead.
	void UnblockRespawnCapabilities(AHazePlayerCharacter Player)
	{
		if(!bRespawnBlocked[Player])
			return;

		Player.UnblockCapabilities(n"Respawn", this);
		bRespawnBlocked[Player] = false;
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UIslandGigaSlideRespawnManagerVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandGigaSlideRespawnManagerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandGigaSlideRespawnManagerVisualizerComponent;

	TArray<AIslandGigaSlideRespawnVolume> Volumes;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Manager = Cast<AIslandGigaSlideRespawnManager>(Component.Owner);

		TListedActors<AIslandGigaSlideRespawnVolume> RespawnVolumes;
		Volumes = RespawnVolumes.Array;

		for(int i = 0; i < Volumes.Num(); i++)
		{
			AIslandGigaSlideRespawnVolume Volume = Volumes[i];
			FLinearColor TextColor = Volume.bIsCheckPoint ? FLinearColor::Green : FLinearColor::Red;

			SetHitProxy(FName("Volume" + i));
			DrawWireBox(Volume.ActorLocation, Volume.ActorScale3D * 100.0, Volume.ActorQuat, FLinearColor::LucBlue, 10.0);
			DrawLine(Manager.ActorLocation, Volume.ActorLocation, TextColor, 10.0);
			DrawPoint(Volume.ActorLocation, FLinearColor::LucBlue, 30.0);
			ClearHitProxy();

			SetHitProxy(FName("RespawnPointType" + i));
			FVector Origin = Volume.ActorLocation + FVector::UpVector * 50.0;
			DrawPoint(Origin, TextColor, 30.0);
			DrawWorldString(Volume.bIsCheckPoint ? "Checkpoint" : "Respawn Point", Origin, TextColor, 1.5, -1, false, true);
			ClearHitProxy();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		FString ProxyString = HitProxy.ToString();
		if(ProxyString.Contains("RespawnPointType"))
		{
			ProxyString.RemoveFromStart("RespawnPointType");
			int Index = String::Conv_StringToInt(ProxyString);
			AIslandGigaSlideRespawnVolume Volume = Volumes[Index];

			Volume.bIsCheckPoint = !Volume.bIsCheckPoint;
			return true;
		}
		else if(ProxyString.Contains("Volume"))
		{
			ProxyString.RemoveFromStart("Volume");
			int Index = String::Conv_StringToInt(ProxyString);
			AIslandGigaSlideRespawnVolume Volume = Volumes[Index];

			Editor::SelectActor(Volume);
		}

		return false;
	}
}
#endif