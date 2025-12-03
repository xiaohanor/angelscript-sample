
delegate void FOnDevCutsceneEvent();

const FConsoleVariable CVar_SkipDevCutscenes("Haze.SkipDevCutscenes", 0);

USTRUCT()
struct FDevCutsceneTextAndDuration
{
	UPROPERTY(EditAnywhere, Meta = (MultiLine = "true"))
	FString Text;

	UPROPERTY(EditAnywhere)
	float Duration = 5.0;
}

enum EDevCutsceneTarget
{
	Fullscreen,
	Mio,
	Zoe,
}

enum EDevCutsceneProgressionType
{
	Duration,
	Input,
}

struct FDevCutsceneFadeOutParams
{
	UPROPERTY()
	bool bUseFadeDurations = true;

	UPROPERTY()
	float FadeOutTime = 2.0;

	UPROPERTY()
	float FadeInTime = 1.0;
}

UCLASS(Abstract)
class ADevCutscene : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	default CapabilityRequestComp.InitialStoppedPlayerCapabilities.Add(n"DevCutsceneInputCapability");

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDevCutsceneWidget> WidgetClass;

	UPROPERTY(EditAnywhere)
	TArray<FDevCutsceneTextAndDuration> DisplayTexts;

	UPROPERTY(EditAnywhere)
	UHazeCapabilitySheet CapabilitySheet = nullptr;

	UPROPERTY(EditAnywhere)
	EDevCutsceneProgressionType ProgressionType = EDevCutsceneProgressionType::Input;

	UPROPERTY(EditAnywhere)
	float InputTimeToProgess = 1.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeSkipCutsceneOnePlayerWidget> SkipCutsceneOnePlayerWidgetClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeSkipCutsceneTwoPlayersWidget> SkipCutsceneTwoPlayersWidgetClass;

	UPROPERTY(Transient, NotEditable, NotVisible)
	TArray<FHazeParticipatingPlayerCutsceneData> ParticipatingPlayers;

	UPROPERTY(Transient, NotEditable, NotVisible)
	UDevCutsceneWidget Widget;

	UPROPERTY(Transient, NotEditable, NotVisible)
	UHazeSkipCutsceneOnePlayerWidget SkipSequenceOnePlayerWidget = nullptr;

	UPROPERTY(Transient, NotEditable, NotVisible)
	UHazeSkipCutsceneTwoPlayersWidget SkipSequenceTwoPlayersWidget = nullptr;

	AHazePlayerCharacter TargetPlayer;

	EDevCutsceneTarget Target;
	FDevCutsceneFadeOutParams FadeParams;
	FOnDevCutsceneEvent FinishedDelegate;
	//FOnDevCutsceneEvent ProgressedDelegate;

	float CurTime = 0.0;
	int CurIndex = 0;
	bool bPlaying = false;

	bool bHasAddedSkipSequenceWidget = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (CapabilitySheet != nullptr)
			CapabilityRequestComp.InitialStoppedSheets.AddUnique(CapabilitySheet);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPlaying == false)
			return;

		if (ProgressionType == EDevCutsceneProgressionType::Duration)
			UpdateDurationProgess(DeltaSeconds);
		else if (ProgressionType == EDevCutsceneProgressionType::Input)
			UpdateInputProgess(DeltaSeconds);
	}

	UFUNCTION(BlueprintCallable, Meta = (UseExecPins))
	void Start(EDevCutsceneTarget InTarget, FDevCutsceneFadeOutParams InFadeOutParams = FDevCutsceneFadeOutParams(), FOnDevCutsceneEvent Finished = FOnDevCutsceneEvent()/*, FOnDevCutsceneEvent Progressed = FOnDevCutsceneEvent()*/)
	{
		if (WidgetClass == nullptr)
			return;

		if (bPlaying == true)
			return;

		if (DisplayTexts.Num() == 0)
			return;

		if (CVar_SkipDevCutscenes.GetInt() != 0)
		{
			Finished.ExecuteIfBound();
			return;
		}

		Target = InTarget;
		FadeParams = InFadeOutParams;
		FinishedDelegate = Finished;

		if (Target == EDevCutsceneTarget::Fullscreen)
		{
			TargetPlayer = Game::GetMio();

			FHazeParticipatingPlayerCutsceneData MioData;
			MioData.Player = Game::GetMio();
			ParticipatingPlayers.Add(MioData);

			FHazeParticipatingPlayerCutsceneData ZoeData;
			ZoeData.Player = Game::GetZoe();
			ParticipatingPlayers.Add(ZoeData);
		}
		else if (Target == EDevCutsceneTarget::Mio)
		{
			TargetPlayer = Game::GetMio();

			FHazeParticipatingPlayerCutsceneData MioData;
			MioData.Player = Game::GetMio();
			ParticipatingPlayers.Add(MioData);
		}
		else if (Target == EDevCutsceneTarget::Zoe)
		{
			TargetPlayer = Game::GetZoe();

			FHazeParticipatingPlayerCutsceneData ZoeData;
			ZoeData.Player = Game::GetMio();
			ParticipatingPlayers.Add(ZoeData);
		}

		if (TargetPlayer == nullptr)
			return;

		if(Target == EDevCutsceneTarget::Fullscreen)
		{
			if(FadeParams.bUseFadeDurations)
				FadeOutFullscreen(this, -1.0, FadeParams.FadeOutTime, 0.0);
			else
				FadeOutFullscreen(this, -1.0, 0.0, 0.0);
		}
		else
		{
			if(FadeParams.bUseFadeDurations)
				TargetPlayer.FadeOut(this, -1.0, FadeParams.FadeOutTime, 0.0);
			else
				TargetPlayer.FadeOut(this, -1.0, 0.0, 0.0);
		}

		if(FadeParams.bUseFadeDurations)
		{
			if (FadeParams.FadeOutTime == 0.0)
				Start_Internal();
			else
				Timer::SetTimer(this, n"Start_Internal", FadeParams.FadeOutTime);
		}
		else
		{
			Start_Internal();
		}
	}

	UFUNCTION()
	private void Start_Internal()
	{
		if(Target == EDevCutsceneTarget::Fullscreen)
		{
			TargetPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		}

		for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
		{
			CapabilityRequestComp.StartInitialSheetsAndCapabilities(PlayerData.Player, this);
			UDevCutscenePlayerComponent::GetOrCreate(PlayerData.Player).ActiveDevCutscene = this;
		}

		Widget = TargetPlayer.AddWidget(WidgetClass, EHazeWidgetLayer::Dev);
		Widget.DisplayText = FText::FromString(DisplayTexts[0].Text);

		CurTime = 0.0;
		CurIndex = 0;
		bPlaying = true;

		//ProgressedDelegate = Progressed;
	}

	UFUNCTION(BlueprintCallable)
	void Stop()
	{
		if (bPlaying == false)
			return;

		if (TargetPlayer == nullptr)
			return;

		for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
		{
			CapabilityRequestComp.StopInitialSheetsAndCapabilities(PlayerData.Player, this);
			UDevCutscenePlayerComponent::Get(PlayerData.Player).ActiveDevCutscene = nullptr;
		}

		TargetPlayer.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);

		if(Target == EDevCutsceneTarget::Fullscreen)
		{
			if(FadeParams.bUseFadeDurations)
				ClearFullscreenFade(this, FadeParams.FadeInTime);
			else
				ClearFullscreenFade(this, 0.0);
		}
		else
		{
			if(FadeParams.bUseFadeDurations)
				TargetPlayer.ClearFade(this, FadeParams.FadeInTime);
			else
				TargetPlayer.ClearFade(this, 0.0);
		}

		TargetPlayer.RemoveWidget(Widget);

		bPlaying = false;
		TargetPlayer = nullptr;
		ParticipatingPlayers.Reset();

		FinishedDelegate.ExecuteIfBound();
	}

	void UpdateDurationProgess(float DeltaSeconds)
	{
		CurTime += DeltaSeconds;

		if (CurTime >= DisplayTexts[CurIndex].Duration)
		{
			CurTime = 0;
			ProgressDevCutscene();
		}
	}

	void UpdateInputProgess(float DeltaSeconds)
	{
		bool bIsReadyToSkip = true;

		AddSkipSequenceWidgetToScreen();

		for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
		{
			UpdatePlayerInputProgessValue(DeltaSeconds, PlayerData);
			
			if (!IsPlayerReadyToProgess(PlayerData))
				bIsReadyToSkip = false;
		}

		if (bIsReadyToSkip && HasControl())
		{
			NetProgressDevCutscene();			
			return;
		}			

		if (ParticipatingPlayers.Num() == 1)
		{
			SkipSequenceOnePlayerWidget.ProgressValue = ParticipatingPlayers[0].SkipProgressValue;
		}
		else if (ParticipatingPlayers.Num() == 2)
		{
			for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
			{
				if (PlayerData.Player.IsZoe())
				{
					SkipSequenceTwoPlayersWidget.RightProgressValue = PlayerData.SkipProgressValue;
				}
				else
				{
					SkipSequenceTwoPlayersWidget.LeftProgressValue = PlayerData.SkipProgressValue;
				}
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetProgressDevCutscene()
	{
		RemoveSkipSequenceWidgetFromScreen();
		ResetInputProgess();
		ProgressDevCutscene();
	}

	void UpdatePlayerInputProgessValue(float DeltaSeconds, FHazeParticipatingPlayerCutsceneData& InPlayerData)
	{
		const float TargetAlpha = InPlayerData.bWantsToSkip ? 1.0 : 0.0;

		if (InputTimeToProgess <= 0.0)
			InPlayerData.SkipProgressValue = TargetAlpha;

		float InterpSpeed = 1.0 / InputTimeToProgess;
		InPlayerData.SkipProgressValue = Math::FInterpConstantTo(InPlayerData.SkipProgressValue, TargetAlpha, DeltaSeconds, InterpSpeed);
	}

	void ResetInputProgess()
	{
		for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
		{
			PlayerData.SkipProgressValue = 0.0;
		}
	}

	bool IsPlayerReadyToProgess(FHazeParticipatingPlayerCutsceneData& InPlayerData)
	{
		return InPlayerData.bWantsToSkip && InPlayerData.SkipProgressValue == 1.0;
	}

	void ProgressDevCutscene()
	{
		CurIndex++;

		if (DisplayTexts.IsValidIndex(CurIndex))
		{
			Widget.DisplayText = FText::FromString(DisplayTexts[CurIndex].Text);
			//ProgressedDelegate.ExecuteIfBound();
		}
		else
		{
			Stop();
		}
	}

	void SetPlayerWantsToProgress(EHazePlayer InPlayer, bool bInWantsToProgress)
	{
		if (!bPlaying)
			return;

		for (FHazeParticipatingPlayerCutsceneData& PlayerData : ParticipatingPlayers)
		{
			if (PlayerData.Player != nullptr && PlayerData.Player.Player == InPlayer)
				PlayerData.bWantsToSkip = bInWantsToProgress;
		}
	}

	void AddSkipSequenceWidgetToScreen()
	{
		if (bHasAddedSkipSequenceWidget)
			return;

		if (ParticipatingPlayers.Num() == 1)
		{
			if (SkipSequenceOnePlayerWidget == nullptr)
			{
				SkipSequenceOnePlayerWidget = Widget::AddFullscreenWidget(SkipCutsceneOnePlayerWidgetClass, EHazeWidgetLayer::Overlay);
			}
			else
			{
				Widget::AddExistingFullscreenWidget(SkipSequenceOnePlayerWidget, EHazeWidgetLayer::Overlay);
			}
		}
		else // Covers ParticipatingPlayers.Num() == 2
		{
			if (SkipSequenceTwoPlayersWidget == nullptr)
			{
				SkipSequenceTwoPlayersWidget = Widget::AddFullscreenWidget(SkipCutsceneTwoPlayersWidgetClass, EHazeWidgetLayer::Overlay);
			}
			else
			{
				Widget::AddExistingFullscreenWidget(SkipSequenceTwoPlayersWidget, EHazeWidgetLayer::Overlay);
			}
		}

		bHasAddedSkipSequenceWidget = true;
	}

	void RemoveSkipSequenceWidgetFromScreen()
	{
		if (!bHasAddedSkipSequenceWidget)
			return;

		if (SkipSequenceOnePlayerWidget != nullptr)
			Widget::RemoveFullscreenWidget(SkipSequenceOnePlayerWidget);
		
		if (SkipSequenceTwoPlayersWidget != nullptr)
			Widget::RemoveFullscreenWidget(SkipSequenceTwoPlayersWidget);

		bHasAddedSkipSequenceWidget = false;
	}
}