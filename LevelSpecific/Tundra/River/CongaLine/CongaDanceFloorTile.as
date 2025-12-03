event void FCongaDanceFloorTilePlayerImpactEvent(AHazePlayerCharacter Player);

class ACongaDanceFloorTile : ACongaGlowingTile
{
	access DanceFloor = private, ACongaLineDanceFloor;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UTundra_SimonSaysPerchPointTargetable SimonSaysTargetable;

	UPROPERTY()
	FCongaDanceFloorTilePlayerImpactEvent OnPlayerImpactTile;

	UPROPERTY()
	FCongaDanceFloorTilePlayerImpactEvent OnPlayerImpactEndTile;

	UPROPERTY(NotVisible, BlueprintHidden)
	ACongaLineDanceFloor DanceFloor;

	private TPerPlayer<bool> PlayerIsOnTile;
	default PlayerIsOnTile[0] = false;
	default PlayerIsOnTile[1] = false;

	private FVector OriginalLocation;
	private TArray<FInstigator> EnableInstigators;

	bool bIgnoreTileCount = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		// Disable all targetables by default, enable them when they are actually risen up and part of a stage
		SimonSaysTargetable.Disable(this);
		OriginalLocation = ActorLocation;
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void SelectDanceFloor()
	{
		Editor::SelectActor(DanceFloor);
	}
#endif

	FVector GetOriginalLocation()
	{
		return OriginalLocation;
	}

	void Enable(FInstigator Instigator)
	{
		EnableInstigators.AddUnique(Instigator);
		SetActive(IsEnabled());
	}

	void Disable(FInstigator Instigator)
	{
		EnableInstigators.RemoveSingleSwap(Instigator);
		SetActive(IsEnabled());
	}

	bool IsEnabled()
	{
		return EnableInstigators.Num() > 0;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float PreviousValue = BrightnessAlphaSmoothed.Value;
		Super::Tick(DeltaSeconds);

		if(CongaLine::GetDanceFloor() != nullptr && !bIgnoreTileCount && CongaLine::IsCongaLineActive() && !bDiscoModeActive)
		{
			if(PreviousValue < 0.99 && BrightnessAlphaSmoothed.Value >= 0.99)
			{
				FCongaTileLightUpEventParams Params;
				Params.Tile = this;

				UCongaLineManagerEventHandler::Trigger_TileLightUp(CongaLine::GetManager(), Params);
				CongaLine::GetDanceFloor().CountLitTile();
			}
			else if(PreviousValue >= 0.99 && BrightnessAlphaSmoothed.Value < 0.99)
				CongaLine::GetDanceFloor().RemoveLitTile();
		}
		
	}


	void ResetLocationToOriginal()
	{
		ActorLocation = OriginalLocation;
	}

	void SetCollisionActive(bool bActive)
	{
		Mesh.CollisionProfileName = bActive ? n"BlockAllDynamic" : n"NoCollision";
	}

	void SimonSaysOnPlayerImpact(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		CrumbSimonSaysOnPlayerImpact(Player);
	}

	void SimonSaysOnPlayerImpactEnd(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		CrumbSimonSaysOnPlayerImpactEnd(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSimonSaysOnPlayerImpact(AHazePlayerCharacter Player)
	{
		PlayerIsOnTile[Player] = true;
		OnPlayerImpactTile.Broadcast(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSimonSaysOnPlayerImpactEnd(AHazePlayerCharacter Player)
	{
		PlayerIsOnTile[Player] = false;
		OnPlayerImpactEndTile.Broadcast(Player);
	}

	bool IsAnyPlayerOnTile()
	{
		return PlayerIsOnTile[0] || PlayerIsOnTile[1];
	}

	bool IsMioOnTile()
	{
		return PlayerIsOnTile[Game::Mio];
	}

	bool IsZoeOnTile()
	{
		return PlayerIsOnTile[Game::Mio];
	}

	bool IsPlayerOnTile(AHazePlayerCharacter Player)
	{
		return PlayerIsOnTile[Player];
	}
};