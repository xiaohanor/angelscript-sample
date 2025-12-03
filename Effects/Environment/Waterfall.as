/**
 * this is for when the dragons slash through the waterfall. We keep track of 
 * when the actors enter the waterfall and when the camera goes in and spawn effects based on that.
 */

class AWaterfall : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent, Category = "Waterfall")
	UStaticMeshComponent WaterfallMesh;
	default WaterfallMesh.Mobility = EComponentMobility::Static;
	default WaterfallMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(EditAnywhere, Category = "Waterfall")
	AActorTrigger TriggerVolume;

    UPROPERTY(EditAnywhere, Category = "Waterfall|Camera")
	UNiagaraSystem CameraVFX;

	/** Offset the VFX attachment (in local space away from the camera) */
    UPROPERTY(EditAnywhere, Category = "Waterfall|Camera")
	FVector CameraVFXLocalOffset = FVector(50, 0, 0);

	/** Whether we want to render the VFX for the other player as well. Mainly for debug purposes. */
    UPROPERTY(EditAnywhere, Category = "Waterfall|Camera")
	bool bRenderForOtherPlayer = false;

    private TPerPlayer<FPlayerCameraWaterfallPerPlayerData> PerPlayerData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// don't tick until player enters the volume
		SetActorTickEnabled(false);

		if(TriggerVolume == nullptr)
		{
			//Removing for now, as some waterfalls won't have references for a while
			// devError("the Waterfall Events need a TriggerVolume assigned to work");
			return;
		}

		TriggerVolume.OnActorEnter.AddUFunction(this, n"OnActorEnterTrigger");
		TriggerVolume.OnActorLeave.AddUFunction(this, n"OnActorExitTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			HandleCameraVFX(Player);
		}
	}

	// spawns and updates transform for camera VFX
	void HandleCameraVFX(AHazePlayerCharacter Player)
	{
		auto& PlayerData = PerPlayerData[Player];

		// we don't do anything until player has entered the waterfall
		if(!PlayerData.bPlayerHasEnteredVolume)
			return;

		// spawn the vfx 
		if(!PlayerData.bCameraEffectTriggered)
		{
			const FBox CameraLocationSweepBox = FBox(PlayerData.PrevCameralocation, Player.ViewLocation);
			const bool bCameraOverlappedTrigger = TriggerVolume.Bounds.Box.Intersect(CameraLocationSweepBox);

			if(bCameraOverlappedTrigger)
			{
				PlayerData.bCameraEffectTriggered = true;

				PlayerData.CameraVFX = Niagara::SpawnOneShotNiagaraSystemAtLocation(
					CameraVFX,
					Player.ViewLocation,
					Player.ViewRotation
				);

				// early return in case niagaracomp was pre-culled
				if (PlayerData.CameraVFX == nullptr)
					return;

				PlayerData.CameraVFX.SetRenderedForPlayer(Player, true);
				PlayerData.CameraVFX.SetRenderedForPlayer(Player.OtherPlayer, bRenderForOtherPlayer);

				// we reset it temporarily for now due to prototyping. In the end this will just be a oneshot
				PlayerData.CameraVFX.OnSystemFinished.AddUFunction(this, n"OnCameraVFXFinished");

				return;
			}
		}

		// update the transform for the vfx until it has been auto destroyed
		if(PlayerData.CameraVFX != nullptr)
		{
			PlayerData.CameraVFX.WorldTransform = Player.ViewTransform;
			PlayerData.CameraVFX.AddLocalOffset(CameraVFXLocalOffset);

			// Debug::DrawDebugCoordinateSystem(
			// 	PlayerData.CameraVFX.WorldTransform.GetLocation(),
			// 	PlayerData.CameraVFX.WorldTransform.GetRotation().Rotator(),
			// 	100
			// );

		}

		PlayerData.PrevCameralocation = Player.ViewLocation;
	}

	UFUNCTION()
	private void OnCameraVFXFinished(UNiagaraComponent PSystem)
	{
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			if(PlayerData.CameraVFX == PSystem)
			{
				PSystem.Deactivate();
				PSystem.DestroyComponent(PSystem);
				PlayerData.CameraVFX = nullptr;
				PlayerData.bCameraEffectTriggered = false;
			}
		}
	}

	AHazePlayerCharacter FindPlayerOnActor(AHazeActor Actor)
	{
		if(Actor == nullptr)
			return nullptr;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr)
			return Player;

		if(Player == nullptr)
		{
			TArray<AActor> OutActors;
			Actor.GetAttachedActors(OutActors, true, true);
			for(AActor ActorIter : OutActors)
			{
				AHazePlayerCharacter PotentialPlayer = Cast<AHazePlayerCharacter>(ActorIter);
				if(PotentialPlayer != nullptr)
				{
					return PotentialPlayer;
				}
			}
		}

		return nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorEnterTrigger(AHazeActor Actor)
	{

		AHazePlayerCharacter Player = FindPlayerOnActor(Actor);

		if(Player != nullptr)
		{
			// flag that we allow the camera VFX to be spawned
			PerPlayerData[Player].bPlayerHasEnteredVolume = true;

			PerPlayerData[Player].PrevCameralocation = Player.ViewLocation;

			// start ticking once the players enter
			SetActorTickEnabled(true);
			UWaterfallEffectHandler::Trigger_OnPlayerEnterWaterfall(this, FWaterfallPlayerEnterParams(Player));
		}

		OnActorEnterWaterfall(Actor);
		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorExitTrigger(AHazeActor Actor)
	{
		OnActorLeaveWaterfall(Actor);

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr)
			UWaterfallEffectHandler::Trigger_OnPlayerLeaveWaterfall(this, FWaterfallPlayerExitParams(Player));
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnActorEnterWaterfall(AHazeActor Actor) { }

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnActorLeaveWaterfall(AHazeActor Actor) { }

}

struct FPlayerCameraWaterfallPerPlayerData
{
	UNiagaraComponent CameraVFX = nullptr;
	bool bCameraEffectTriggered = false;
	bool bPlayerHasEnteredVolume = false;
	FVector PrevCameralocation = FVector::ZeroVector;
};