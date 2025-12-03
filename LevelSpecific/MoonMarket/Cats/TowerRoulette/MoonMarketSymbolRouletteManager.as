struct FMoonMarketSymbolRouletteLineData
{
	UPROPERTY()
	TArray<AMoonMarketSymbolCube> Cubes;
	UPROPERTY()
	AActor AssociatedPlatform;
}

enum EMoonMarketSymbolRouletteState
{
	Disabled,
	Initiate,
	SetLine,
	RouletteSpin,
	Countdown,
	CheckAnswer
}

class AMoonMarketSymbolRouletteManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectSymbol;
	default EffectSymbol.SetAutoActivate(false);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSymbolInitiateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSymbolRevealCubesCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSymbolRouletteSpinCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSymbolCountdownCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSymbolCheckAnswerCapability");

	UPROPERTY(EditInstanceOnly)
	AMoonMarketSymbolCube RouletteCube1;
	UPROPERTY(EditInstanceOnly)
	AMoonMarketSymbolCube RouletteCube2;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketSymbolCompletedPlatform FinalPlatform;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<AStaticCameraActor> PlayerCameras;

	UPROPERTY(EditInstanceOnly)
	TArray<AMoonMarketClockTowerLever> Levers;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger EndPlayerTrigger;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RestartPoint;

	EMoonMarketSymbolRouletteState State;

	// UPROPERTY(DefaultComponent)
	// UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditInstanceOnly)
	TArray<FMoonMarketSymbolRouletteLineData> CubeData;

	TArray<EMoonMarketRouletteSymbolType> AvailableTypes;
	TArray<EMoonMarketRouletteSymbolType> ChosenTypes;

	int LineIndex;

	bool bRouletteCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// ActionQueueComp.SetPaused(true);
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		EndPlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		RouletteCube1.AddActorDisable(this);
		RouletteCube2.AddActorDisable(this);
		InitiateAllCubes();
	}

	//Activate
	//Raise cubes
	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		State = EMoonMarketSymbolRouletteState::Initiate;
	}

	//Run roulette
	void ChooseTypes()
	{
		int Choice1 = Math::RandRange(0, AvailableTypes.Num() - 1);
		int Choice2 = Math::RandRange(0, AvailableTypes.Num() - 1);
		RouletteCube1.ManuallySetType(AvailableTypes[Choice1]);
		RouletteCube2.ManuallySetType(AvailableTypes[Choice2]);
	}

	void SetLine()
	{
		ActivateCubeLine(LineIndex);
	}

	void IncrementLineIndex()
	{
		LineIndex++;
	}

	void DeactivateAllCubes()
	{
		for (FMoonMarketSymbolRouletteLineData Data : CubeData)
		{
			for (AMoonMarketSymbolCube Cube : Data.Cubes)
			{
				Cube.DeactivateCube();
			}
		}
	}

	void InitiateAllCubes()
	{
		for (FMoonMarketSymbolRouletteLineData Data : CubeData)
		{
			for (AMoonMarketSymbolCube Cube : Data.Cubes)
			{
				Cube.InitiateCube();
			}
		}
	}

	void SetCubeAnswerColours()
	{
		for (AMoonMarketSymbolCube Cube : CubeData[LineIndex].Cubes)
		{
			if (Cube.bPlayerIsTouching)
			{
				if (Cube.Type == RouletteCube1.Type || Cube.Type == RouletteCube2.Type)
				{
					Cube.SetCubeAnswer(true);
				}
				else
				{
					Cube.SetCubeAnswer(false);
				}
			}
		}
	}

	private void ActivateCubeLine(int Index)
	{
		AvailableTypes.Empty();

		for (AMoonMarketSymbolCube Cube : CubeData[Index].Cubes)
		{
			if (!AvailableTypes.Contains(Cube.Type))
				AvailableTypes.Add(Cube.Type);
		}	

		for (AMoonMarketSymbolCube Cube : CubeData[Index].Cubes)
		{
			Cube.ActivateCube();
		}
	}

	void DeactivateRoulette()
	{
		EffectSymbol.Activate();
		RouletteCube1.AddActorDisable(this);
		RouletteCube2.AddActorDisable(this);

		DeactivateAllCubes();

		for ( AMoonMarketClockTowerLever Lever : Levers)
		{
			Lever.ResetLever();
		}

		DoubleInteract.RemoveActorDisable(this);
	}

	void CompleteRoulette()
	{
		EffectSymbol.Activate();
		RouletteCube1.AddActorDisable(this);
		RouletteCube2.AddActorDisable(this);

		DeactivateAllCubes();

		for ( AMoonMarketClockTowerLever Lever : Levers)
		{
			Lever.ResetLever();
		}

		DoubleInteract.RemoveActorDisable(this);

		for (int i = 0; i < CubeData.Num() - 2; i++)
		{
			Print("CUBE LINE: " + i + " DEACTIVATE");
			for (AMoonMarketSymbolCube Cube : CubeData[i].Cubes)
			{
				Cube.DeactivateCube();
			}
		}

		FinalPlatform.ActivateFinalPlatform();

		bRouletteCompleted = true;
	}

	void ActivateHead()
	{
		EffectSymbol.Activate();
		RouletteCube1.RemoveActorDisable(this);
		RouletteCube2.RemoveActorDisable(this);
		DoubleInteract.AddActorDisable(this);
	}

	void ActivateRoulette()
	{
		if (bRouletteCompleted)
			return;
		
		LineIndex = 0;
		State = EMoonMarketSymbolRouletteState::SetLine;
	}

	bool HasCorrectAnswer()
	{
		int CorrectStanding = 0;

		for (AMoonMarketSymbolCube Cube : CubeData[LineIndex].Cubes)
		{
			if (Cube.Type == RouletteCube1.Type && Cube.Type == RouletteCube2.Type) 
			{
				if (Cube.NumberOfPlayers() == 2)
				{
					return true;
				}
			}
			
			if (Cube.Type == RouletteCube1.Type || Cube.Type == RouletteCube2.Type) 
			{
				if (Cube.NumberOfPlayers() > 0)
					CorrectStanding++;
			}
		}	

		return CorrectStanding >= 2;
	}

	void ShowAllCubeTimers()
	{
		for (FMoonMarketSymbolRouletteLineData Data : CubeData)
		{
			for (AMoonMarketSymbolCube Cube : Data.Cubes)
			{
				Cube.ShowTimers();
			}
		}
	}

	void UpdateAllCubeTimers(float Alpha)
	{
		for (FMoonMarketSymbolRouletteLineData Data : CubeData)
		{
			for (AMoonMarketSymbolCube Cube : Data.Cubes)
			{
				Cube.UpdateTimers(Alpha);
			}
		}
	}

	void HideAllCubeTimers()
	{
		for (FMoonMarketSymbolRouletteLineData Data : CubeData)
		{
			for (AMoonMarketSymbolCube Cube : Data.Cubes)
			{
				Cube.HideTimers();
			}
		}
	}

	void ResetPlayers()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto Settings = UCameraSettings::GetSettings(Player);
			PlayerCameras[Player].ActorLocation = Player.GetViewLocation();
			PlayerCameras[Player].ActorRotation = Player.GetViewRotation();
			Player.TeleportToRespawnPoint(RestartPoint, this);
			Player.ActivateCamera(PlayerCameras[Player], 0, this);
			Timer::SetTimer(this, n"DelayedCameraActivate", 0.1);
		}
	}

	UFUNCTION()
	void DelayedCameraActivate()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this, 2.0);
		}
	}

	bool HasCompleted()
	{
		return LineIndex >= CubeData.Num() - 1;
	}
	
	//End roulette + raise platform underneath
	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
	}
};