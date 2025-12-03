class ACongaLineDanceFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("DanceFloor");
	default EditorBillboard.RelativeLocation = FVector(0.0, 0.0, 500.0);
	default EditorBillboard.RelativeScale3D = FVector(0.75);
#endif

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent MioSide;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent ZoeSide;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	TPerPlayer<UCongaLinePlayerComponent> PlayerDanceComps;

	UPROPERTY(EditAnywhere)
	int Width = 9;

	UPROPERTY(EditAnywhere)
	int Height = 9;

	UPROPERTY(EditAnywhere)
	float TileHeight = 500.0;

	UPROPERTY(EditAnywhere)
	FLinearColor DefaultTileColor = FLinearColor::Gray;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ExponentialCurve;

	bool bUseCurve = true;

	TPerPlayer<int> MonkeyCount;
	TPerPlayer<bool> bAllMonkeysCollected;

	private int LitTilesCount = 0;

	bool bAllMonkeysCollectedOnce = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACongaDanceFloorTile> TileClass;

	UPROPERTY(EditInstanceOnly)
	bool bGenerateTilesInEditor = false;

	UPROPERTY(NotVisible, BlueprintHidden)
	TArray<ACongaDanceFloorTile> Tiles;

	TPerPlayer<float> LastRowLitTime;
	TPerPlayer<int> LitRows;
	float TimeBetweenRowsLit = 0.06;

	int IndexShift = 0;

	bool bDiscoModeActive = false;
	float DiscoFloorStrength;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerDanceComps[Game::Mio] = UCongaLinePlayerComponent::Get(Game::Mio);
		PlayerDanceComps[Game::Zoe] = UCongaLinePlayerComponent::Get(Game::Zoe);

		if(Tiles.Num() != Width * Height)
		{
			ConstructDanceFloor(false);
			Mesh.SetVisibility(false);
		}
		else
		{
			//SetDefaultColors();
		}

		CongaLine::GetManager().OnMonkeyAmountChangedEvent.AddUFunction(this, n"OnMonkeyAmountChanged");
		MioSide.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		MioSide.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		ZoeSide.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		ZoeSide.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void SetDiscoModeActive(bool bActive, float FloorStrength = 1)
	{
		DiscoFloorStrength = FloorStrength;
		bDiscoModeActive = bActive;

		for(auto Tile : Tiles)
		{
			Tile.SetDiscoMode(bActive, FloorStrength);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bDiscoModeActive)
		{
			int NewIndexShift = Math::FloorToInt(Time::GameTimeSeconds);
			if(IndexShift != NewIndexShift)
			{
				IndexShift = NewIndexShift;
				for(int x = 0; x < Width; x++)
				{
					for(int y = 0; y < Height; y++)
					{
						ACongaDanceFloorTile Tile = Tiles[x * Height + y];
						Tile.ApplyColorOverride(x * Height + y + IndexShift, this, EInstigatePriority::Low);
					}
				}
			}
		}

		if(!CongaLine::IsCongaLineActive())
			return;

		#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Dance Floor");
		TemporalLog.Value("Mio Monkey Amount", MonkeyCount[Game::Mio]);
		TemporalLog.Value("Zoe Monkey Amount", MonkeyCount[Game::Zoe]);
		#endif

		for(auto Player : Game::GetPlayers())
		{
			if(Time::GetGameTimeSince(LastRowLitTime[Player]) >= TimeBetweenRowsLit)
			{
				int MaxMonkeysPerPlayer = Math::IntegerDivisionTrunc( CongaLine::GetManager().MonkeyCounter.MonkeysPerStage, 2);
				float Percentage = MonkeyCount[Player] / float(MaxMonkeysPerPlayer);
				const int TargetLitRows = Math::FloorToInt(Percentage * Height);
				
				if(LitRows[Player] < TargetLitRows)
				{
					LitRows[Player]++;

					if(bAllMonkeysCollectedOnce)
						UCongaLineManagerEventHandler::Trigger_RowLit(CongaLine::GetManager());
				}
				else if(LitRows[Player] > TargetLitRows)
				{
					LitRows[Player]--;

					if(bAllMonkeysCollectedOnce)
						UCongaLineManagerEventHandler::Trigger_RowUnlit(CongaLine::GetManager());
				}
				UpdateDanceFloorMat(Player);

				LastRowLitTime[Player] = Time::GameTimeSeconds;
			}
		}
	}

	UFUNCTION()
	private void OnMonkeyAmountChanged(int TotalMonkeyAmount)
	{
		int MaxMonkeysPerPlayer = Math::IntegerDivisionTrunc( CongaLine::GetManager().MonkeyCounter.MonkeysPerStage, 2);

		for(auto Player : Game::GetPlayers())
		{
			bool AllCollected = PlayerDanceComps[Player].GetDancers().Num() == MaxMonkeysPerPlayer;
			bAllMonkeysCollected[Player] = AllCollected;
		}
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		bool bIsMio = OverlappedComponent == MioSide;
		
		//Monkey
		auto Monkey = Cast<ACongaLineMonkey>(OtherActor);
		if(Monkey != nullptr)
		{
			// if(!Monkey.HasControl())
			// 	return;

			if(Monkey.ColorCode == EMonkeyColorCode::Mio == bIsMio)
			{
				UCongaLineDancerComponent DancerComp = UCongaLineDancerComponent::Get(OtherActor);
				DancerComp.bIsOnDanceFloor = false;
				RecountMonkeys();
			}

			return;
		}

		//Player
		auto PlayerComp = UCongaLinePlayerComponent::Get(OtherActor);
		if(PlayerComp != nullptr)
		{
			// if(!PlayerComp.HasControl())
			// 	return;

			if(Cast<AHazePlayerCharacter>(OtherActor).IsMio() == bIsMio)
				PlayerComp.bIsOnDanceFLoor = false;
		}
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		bool bIsMio = OverlappedComponent == MioSide;

		//Monkey
		auto Monkey = Cast<ACongaLineMonkey>(OtherActor);
		if(Monkey != nullptr)
		{
			// if(!Monkey.HasControl())
			// 	return;

			if(Monkey.ColorCode == EMonkeyColorCode::Mio == bIsMio)
			{
				UCongaLineDancerComponent DancerComp = UCongaLineDancerComponent::Get(OtherActor);
				DancerComp.bIsOnDanceFloor = true;
				RecountMonkeys();
			}
			return;
		}

		//Player
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
			return;

		if(PlayerDanceComps[Player] == nullptr)
			return;

		if(Player.IsMio() == bIsMio)
			PlayerDanceComps[Player].bIsOnDanceFLoor = true;
	}

	UFUNCTION()
	void OnAllMonkeysCollected()
	{
		if(!bAllMonkeysCollectedOnce)
		{
			SetCongaFloorColors();
			LitRows[Game::Mio] = 0;
			LitRows[Game::Zoe] = 0;
		}

		bAllMonkeysCollectedOnce = true;
	}

	UFUNCTION()
	private void OnAllMonkeysLost()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SetDefaultColors()
	{
		for(int x = 0; x < Width; x++)
		{
			for(int y = 0; y < Height; y++)
			{
				ACongaDanceFloorTile Tile = Tiles[x * Height + y];
				Tile.ApplyColorOverride(x * Height + y + IndexShift, this, EInstigatePriority::Normal);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetBlackTiles()
	{
		for(int x = 0; x < Width; x++)
		{
			for(int y = 0; y < Height; y++)
			{
				ACongaDanceFloorTile Tile = Tiles[x * Height + y];
				Tile.SetDefaultColor(FLinearColor::Black);
			}
		}
	}


	void InitiateMonkeyConga()
	{
		CongaLine::GetManager().OnMonkeyBarFilledEvent.AddUFunction(this, n"OnAllMonkeysCollected");
		CongaLine::GetManager().OnMonkeyBarLostEvent.AddUFunction(this, n"OnAllMonkeysLost");
		CongaLine::GetManager().OnWinEvent.AddUFunction(this, n"ClearCongaColors");

		SetBlackTiles();
	}


	UFUNCTION(CallInEditor)
	void RegenerateDanceFloor()
	{
		ConstructDanceFloor(true);
		Mesh.SetVisibility(false);
	}

	void ConstructDanceFloor(bool bCalledInEditor)
	{
		const int TileSize = Math::FloorToInt(100 * Mesh.WorldScale.X / float(Width));
		const float HalfWidth = (100 * Mesh.WorldScale.X / 2.0) - TileSize / 2.0;
		const FVector TopLeft = ActorLocation - (ActorRightVector * HalfWidth) - (ActorForwardVector * HalfWidth);


		if(bCalledInEditor)
		{
#if EDITOR
			TArray<AActor> Children;
			GetAttachedActors(Children);
			for(auto Tile : Children)
			{
				Tile.DestroyActor();
			}

			TArray<AActor> EditorActors = Editor::GetAllEditorWorldActorsOfClass(ACongaDanceFloorTile);
			EditorDestroyIncompatibleTiles(EditorActors);
			EditorRebuildTilesArray(EditorActors);
			HandleSpawnTiles();
#endif
		}
		else
		{
			HandleSpawnTiles();
		}

		for(int x = 0; x < Width; x++)
		{
			for(int y = 0; y < Height; y++)
			{
				FVector XOffset = (ActorRightVector * x * TileSize);
				//if(y % 2 == 0) 
				//	XOffset = ActorRightVector * (Width - 1 - x) * TileSize;

				ACongaDanceFloorTile Tile = Tiles[x * Height + y];

				FVector TilePos = TopLeft + (ActorForwardVector * y * TileSize) + XOffset;
				
				Tile.ActorLocation = TilePos;
				Tile.DanceFloor = this;

				FBox Bounds = Tile.GetActorLocalBoundingBox(false);

				FVector Size = Bounds.Extent * 2.0;

				if(bCalledInEditor)
					Tile.CreateDynamicMaterial();

				Tile.SetDefaultColorByIndex(x * Height + y);
				Tile.SetActorScale3D(FVector(TileSize/Size.X, TileSize/Size.Y, TileHeight/Size.Z));
			}
		}

		if(CongaLine::GetManager() != nullptr)
		{
			InitiateMonkeyConga();
		}
		else
		{
			LightAllTiles();
		}
	}


#if EDITOR
	// Destroys all tiles with an old class
	void EditorDestroyIncompatibleTiles(TArray<AActor>& Actors)
	{
		for(int i = Actors.Num() - 1; i >= 0; --i)
		{
			if(Actors[i].Class != TileClass)
			{
				Actors[i].DestroyActor();
				Actors.RemoveAt(i);
			}
		}
	}

	void EditorDestroyAllTiles()
	{
		TArray<ACongaDanceFloorTile> EditorActors = Editor::GetAllEditorWorldActorsOfClass(ACongaDanceFloorTile);
		for(int i = 0; i < EditorActors.Num(); i++)
		{
			EditorActors[i].DestroyActor();
		}

		Tiles.Empty();
	}

	void EditorRebuildTilesArray(TArray<AActor>& Actors)
	{
		Tiles.Empty();
		for(int i = 0; i < Actors.Num(); i++)
		{
			auto Tile = Cast<ACongaDanceFloorTile>(Actors[i]);
			Tiles.Add(Tile);
		}
	}

	UFUNCTION(DevFunction)
	void ToggleUseExponentialCurve()
	{
		bUseCurve = !bUseCurve;
	}

#endif

	void HandleSpawnTiles()
	{
		int CurrentDifference = Tiles.Num() - Width * Height;
		for(int i = 0; i < Math::Abs(CurrentDifference); i++)
		{
			if(CurrentDifference < 0)
			{
				auto Tile = SpawnActor(TileClass);
				Tile.AttachToActor(this);
				Tiles.Add(Tile);
			}
			else
			{
				Tiles[Tiles.Num() - 1].DestroyActor();
				Tiles.RemoveAt(Tiles.Num() - 1);
			}
		}

		devCheck(Tiles.Num() == Width * Height, "Spawned tiles but num is not the amount it should");
	}

	
	UFUNCTION(DevFunction)
	void SetCongaFloorColors()
	{
		for(int i = 0; i < Tiles.Num(); i++)
		{
			if(Math::IntegerDivisionTrunc(i, Height) == Math::IntegerDivisionTrunc(Height, 2))
			{
				Tiles[i].bIgnoreTileCount = true;
				Tiles[i].ApplyColorOverride(DefaultTileColor, this);
				Tiles[i].SetActive(false);
				continue;
			}
			else if(i < Tiles.Num() / 2.0)
			{
				Tiles[i].ApplyColorOverride(FLinearColor(0.11, 0.63, 0.00), this);
			}
			else
			{
				Tiles[i].ApplyColorOverride(FLinearColor(0.945, 0.145, 1), this);
			}
		}
	}

	UFUNCTION()
	void ClearCongaColors()
	{
		SetDefaultColors();

		for(int i = 0; i < Tiles.Num(); i++)
		{
			Tiles[i].ClearColorOverride(this);
			Tiles[i].SetActive(true);
			Tiles[i].SetMaxStrength(0.4);
		}
	}

	void RecountMonkeys()
	{
		TPerPlayer<int> TempMonkeyCount;
		for(auto Player : Game::GetPlayers())
		{
			if(PlayerDanceComps[Player] == nullptr)
			{
				PlayerDanceComps[Player] = UCongaLinePlayerComponent::Get(Player);
				
				if(PlayerDanceComps[Player] == nullptr)
					return;
			}

			TempMonkeyCount[Player] = 0;

			for(auto Monkey : PlayerDanceComps[Player].GetDancers())
			{
				if(Monkey.bIsOnDanceFloor)
					++TempMonkeyCount[Player];
			}
		}

		if(HasControl())
			NetSetMonkeyAmount(TempMonkeyCount[Game::Mio], TempMonkeyCount[Game::Zoe]);
	}

	UFUNCTION(NetFunction)
	void NetSetMonkeyAmount(int MioAmount, int ZoeAmount)
	{
		if(MonkeyCount[Game::Mio] != MioAmount)
		{
			if(MioAmount < MonkeyCount[Game::Mio])
			{
				LastRowLitTime[Game::Mio] = Time::GameTimeSeconds + TimeBetweenRowsLit;
			}

			MonkeyCount[Game::Mio] = MioAmount;
			UpdateDanceFloorMat(Game::Mio);
		}

		if(MonkeyCount[Game::Zoe] != ZoeAmount)
		{
			if(ZoeAmount < MonkeyCount[Game::Zoe])
			{
				LastRowLitTime[Game::Zoe] = Time::GameTimeSeconds + TimeBetweenRowsLit;
			}

			MonkeyCount[Game::Zoe] = ZoeAmount;
			UpdateDanceFloorMat(Game::Zoe);
		}
	}

	void CountLitTile()
	{
		LitTilesCount++;
		if(LitTilesCount >= (Width * Height) - Height)
		{
			SetDefaultColors();

			if(HasControl())
				NetBroadcastWin();
		}
	}

	UFUNCTION(NetFunction)
	private void NetBroadcastWin()
	{
		CongaLine::GetManager().OnWinEvent.Broadcast();
		CongaLine::GetManager().bIsCompleted = true;
	}

	void RemoveLitTile()
	{
		LitTilesCount--;
	}

	UFUNCTION(DevFunction)
	void DevActivateFloor()
	{
		bAllMonkeysCollectedOnce = !bAllMonkeysCollectedOnce;

		if(!bAllMonkeysCollectedOnce)
		{
			for(int i = 0; i < Tiles.Num(); i++)
			{
				Tiles[i].SetActive(false);
			}
		}

		LitRows[Game::Mio] = 0;
		LitRows[Game::Zoe] = 0;
		LastRowLitTime[Game::Mio] = Time::GameTimeSeconds;
		LastRowLitTime[Game::Zoe] = Time::GameTimeSeconds;
	}

	void UpdateDanceFloorMat(AHazePlayerCharacter Player)
	{
		if(!bAllMonkeysCollectedOnce)
			return;

		const int ColumnsPerPlayer = Math::IntegerDivisionTrunc(Width - 1, 2);
		
		for(int i = 0; i < Tiles.Num(); i++)
		{
			if(Math::IntegerDivisionTrunc(i, Height) == Math::IntegerDivisionTrunc(Height, 2))
				continue;

			if(Player.IsMio() && i > Height * ColumnsPerPlayer)
				break;
			else if(Player.IsZoe() && i < Height * ColumnsPerPlayer)
				continue;

			int Index = i % Height;
			Tiles[Tiles.Num() - 1 - i].SetActive(Index < LitRows[Player]);
		}
	}

	void SetTilesCollisionActive(bool bActive)
	{
		for(int i = 0; i < Tiles.Num(); i++)
		{
			Tiles[i].SetCollisionActive(bActive);
		}
	}

	void LightAllTiles()
	{
		for(int i = 0; i < Tiles.Num(); i++)
		{
			Tiles[i].SetActive(true);
		}
	}

	void UnlightAllTiles()
	{
		for(int i = 0; i < Tiles.Num(); i++)
		{
			Tiles[i].SetActive(false);
		}
	}

	void HandleDispersedMonkeys()
	{
		RecountMonkeys();
	}

	void HandleNewMonkeyGained(UCongaLineDancerComponent NewMonkey)
	{
		RecountMonkeys();
	}
};