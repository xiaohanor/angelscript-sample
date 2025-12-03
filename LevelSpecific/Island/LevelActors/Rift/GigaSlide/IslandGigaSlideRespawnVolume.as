class AIslandGigaSlideRespawnVolume : APlayerTrigger
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandGigaSlideRespawnVolumeVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	bool bIsCheckPoint = false;

	UPROPERTY(EditAnywhere)
	ARespawnPoint MioRespawnPoint;

	UPROPERTY(EditAnywhere)
	ARespawnPoint ZoeRespawnPoint;

	AIslandGigaSlideRespawnManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		TListedActors<AIslandGigaSlideRespawnManager> ListedManager;
		Manager = ListedManager.Single;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		// if(!Manager.bRespawnSystemActive)
		// {
		// 	Manager.ActivateRespawnSystem();
		// }
		
		if(bIsCheckPoint)
		{
			Manager.CurrentCheckpointVolume = this;
		}
		else if(Player.HasControl())
		{
			NetOnEnterNonCheckpoint(Player);
		}
	}

	UFUNCTION(NetFunction)
	private void NetOnEnterNonCheckpoint(AHazePlayerCharacter Player)
	{
		if(!Player.OtherPlayer.IsPlayerDead())
			return;
		
		if(!Manager.CanRespawnPlayer(Player.OtherPlayer))
			return;

		SetStickyFor(Player.OtherPlayer);
		Manager.UnblockRespawnCapabilities(Player.OtherPlayer);
	}

	void SetStickyFor(AHazePlayerCharacter Player)
	{
		Player.SetStickyRespawnPoint(Player.IsMio() ? MioRespawnPoint : ZoeRespawnPoint);
	}

	void SetStickyForBoth()
	{
		SetStickyFor(Game::Mio);
		SetStickyFor(Game::Zoe);
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UIslandGigaSlideRespawnVolumeVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandGigaSlideRespawnVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandGigaSlideRespawnVolumeVisualizerComponent;

	AIslandGigaSlideRespawnManager Manager;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Volume = Cast<AIslandGigaSlideRespawnVolume>(Component.Owner);

		TListedActors<AIslandGigaSlideRespawnManager> ListedManager;
		Manager = ListedManager.Single;

		DrawWireBox(Volume.ActorLocation, Volume.ActorScale3D * 100.0, Volume.ActorQuat, FLinearColor::LucBlue, 10.0);

		FLinearColor TextColor = Volume.bIsCheckPoint ? FLinearColor::Green : FLinearColor::Red;

		SetHitProxy(n"Manager");
		DrawLine(Manager.ActorLocation, Volume.ActorLocation, TextColor, 10.0);
		DrawPoint(Manager.ActorLocation, TextColor, 30.0);
		DrawWorldString("Manager", Manager.ActorLocation, TextColor, 1.5, -1, false, true);
		ClearHitProxy();
		
		if(Volume.MioRespawnPoint != nullptr)
			DrawLine(Volume.ActorLocation, Volume.MioRespawnPoint.ActorLocation, FLinearColor::Red, 10.0);

		if(Volume.ZoeRespawnPoint != nullptr)
			DrawLine(Volume.ActorLocation, Volume.ZoeRespawnPoint.ActorTransform.TransformPosition(Volume.ZoeRespawnPoint.SecondPosition.Location), FLinearColor::Blue, 10.0);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy == n"Manager")
		{
			Editor::SelectActor(Manager);
			return true;
		}

		return false;
	}
}
#endif