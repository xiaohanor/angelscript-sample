class AHoverPerchGrindSplineRespawnVolume : APlayerTrigger
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UHoverPerchRespawnVolumeVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	AHoverPerchGrindSplineRespawnPoint RespawnPoint;

	AHoverPerchRespawnManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		TListedActors<AHoverPerchRespawnManager> ListedManager;
		Manager = ListedManager.Single;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(!Manager.bRespawnSystemActive)
		{
			Manager.ActivateRespawnSystem();
		}

		if(Player.OtherPlayer.IsPlayerDead())
		{
			Manager.SetActiveRespawnVolumeForPlayer(Player.OtherPlayer, this);
		}
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UHoverPerchRespawnVolumeVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UHoverPerchRespawnVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHoverPerchRespawnVolumeVisualizerComponent;

	AHoverPerchRespawnManager Manager;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Volume = Cast<AHoverPerchGrindSplineRespawnVolume>(Component.Owner);

		TListedActors<AHoverPerchRespawnManager> ListedManager;
		Manager = ListedManager.Single;
		if(Manager == nullptr)
			return;

		DrawWireBox(Volume.ActorLocation, Volume.ActorScale3D * 100.0, Volume.ActorQuat, FLinearColor::LucBlue, 10.0);

		FLinearColor TextColor = FLinearColor::Red;

		SetHitProxy(n"Manager");
		DrawLine(Manager.ActorLocation, Volume.ActorLocation, TextColor, 10.0);
		DrawPoint(Manager.ActorLocation, TextColor, 30.0);
		DrawWorldString("Manager", Manager.ActorLocation, TextColor, 1.5, -1, false, true);
		ClearHitProxy();
		
		if(Volume.RespawnPoint != nullptr)
			DrawLine(Volume.ActorLocation, Volume.RespawnPoint.ActorLocation, FLinearColor::Green, 10.0);
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