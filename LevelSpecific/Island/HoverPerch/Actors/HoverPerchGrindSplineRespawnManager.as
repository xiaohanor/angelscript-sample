class AHoverPerchRespawnManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UHoverPerchRespawnManagerVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("S_Player");
#endif

	bool bRespawnSystemActive = false;
	TPerPlayer<UPlayerHealthComponent> HealthComps;
	TPerPlayer<UPlayerRespawnComponent> RespawnComps;
	TPerPlayer<bool> bRespawnBlocked;
	TPerPlayer<AHoverPerchGrindSplineRespawnVolume> ActiveVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			HealthComps[Player] = UPlayerHealthComponent::Get(Player);
			RespawnComps[Player] = UPlayerRespawnComponent::Get(Player);
		}
	}

	UFUNCTION()
	private bool OnRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if(ActiveVolumes[Player] == nullptr)
		{
			devError("Tried to respawn when no volume is active, this shouldn't be possible!");
			return false;
		}

		AHoverPerchGrindSplineRespawnVolume Volume = ActiveVolumes[Player];
		AHoverPerchActor HoverPerch = HoverPerch::GetCurrentPerchForPlayer(Player);
		Volume.RespawnPoint.TeleportHoverPerchToRespawnPoint(HoverPerch);
		OutLocation.RespawnRelativeTo = HoverPerch.PerchComp;

		BlockRespawnCapabilities(Player);
		return true;
	}

	UFUNCTION()
	void ActivateRespawnSystem()
	{
		if(bRespawnSystemActive)
			return;

		BlockRespawnBoth();
		bRespawnSystemActive = true;

		for(auto Player : Game::Players)
		{
			RespawnComps[Player].ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawn"), EInstigatePriority::High);
		}
	}

	UFUNCTION()
	void DeactivateRespawnSystem()
	{
		if(!bRespawnSystemActive)
			return;
		
		UnblockRespawnBoth();
		bRespawnSystemActive = false;

		for(auto Player : Game::Players)
		{
			RespawnComps[Player].ClearRespawnOverride(this);
		}
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

	void SetActiveRespawnVolumeForPlayer(AHazePlayerCharacter Player, AHoverPerchGrindSplineRespawnVolume Volume)
	{
		UnblockRespawnCapabilities(Player);
		ActiveVolumes[Player] = Volume;
	}

	// Block both players respawn capabilities.
	void BlockRespawnCapabilities(AHazePlayerCharacter Player)
	{
		if(bRespawnBlocked[Player])
			return;

		Player.BlockCapabilities(n"Respawn", this);
		bRespawnBlocked[Player] = true;
		ActiveVolumes[Player] = nullptr;
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
class UHoverPerchRespawnManagerVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UHoverPerchRespawnManagerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHoverPerchRespawnManagerVisualizerComponent;

	TArray<AHoverPerchGrindSplineRespawnVolume> Volumes;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Manager = Cast<AHoverPerchRespawnManager>(Component.Owner);

		TListedActors<AHoverPerchGrindSplineRespawnVolume> RespawnVolumes;
		Volumes = RespawnVolumes.Array;

		for(int i = 0; i < Volumes.Num(); i++)
		{
			AHoverPerchGrindSplineRespawnVolume Volume = Volumes[i];
			FLinearColor TextColor = FLinearColor::Red;

			SetHitProxy(FName("Volume" + i));
			DrawWireBox(Volume.ActorLocation, Volume.ActorScale3D * 100.0, Volume.ActorQuat, FLinearColor::LucBlue, 10.0);
			DrawLine(Manager.ActorLocation, Volume.ActorLocation, TextColor, 10.0);
			DrawPoint(Volume.ActorLocation, FLinearColor::LucBlue, 30.0);
			ClearHitProxy();

			if(Volume.RespawnPoint != nullptr)
				DrawLine(Volume.ActorLocation, Volume.RespawnPoint.ActorLocation, FLinearColor::Green, 10.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		FString ProxyString = HitProxy.ToString();
		if(ProxyString.Contains("Volume"))
		{
			ProxyString.RemoveFromStart("Volume");
			int Index = String::Conv_StringToInt(ProxyString);
			AHoverPerchGrindSplineRespawnVolume Volume = Volumes[Index];

			Editor::SelectActor(Volume);
		}

		return false;
	}
}
#endif