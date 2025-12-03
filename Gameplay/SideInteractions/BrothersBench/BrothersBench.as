struct FBrothersBenchPerPlayerData
{
	UThreeShotInteractionComponent Interaction;
	float SitDownTime = -1;

	bool IsSitting() const
	{
		return Interaction != nullptr;
	}
};

asset BrothersBenchBlendCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                                           ...····''''''''''''''|
	    |                                       .·''                     |
	    |                                    .·'                         |
	    |                                 .·'                            |
	    |                               .·                               |
	    |                             .'                                 |
	    |                           ·'                                   |
	    |                         ·'                                     |
	    |                       ·'                                       |
	    |                     ·'                                         |
	    |                  .·'                                           |
	    |                .·                                              |
	    |              .'                                                |
	    |           .·'                                                  |
	    |        .·'                                                     |
	0.0 |.....·''                                                        |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddCurveKeyTangent(0.7, 0.95, 0.47019);
	AddAutoCurveKey(1.0, 1.0);
};

asset BrothersBenchBenchBlend of UCameraOrbitBlend
{
	AlphaType = ECameraBlendAlphaType::Curve;
	BlendCurve.ExternalCurve = BrothersBenchBlendCurve;
};

enum EBrothersBenchID
{
	Skyline,
	Tundra,
	Island,
	Summit,
	Prison,
	Sanctuary,

	MAX
}

enum EBrothersBenchBlendState
{
	None,
	ProjectionBlending,
	ProjectionBlended,
	WaitForVista,
	Vista,
};

UCLASS(Abstract)
class ABrothersBench : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	FRuntimeFloatCurve CurveTest;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent LeftInteraction;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent RightInteraction;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent BenchCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent VistaCamera;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UBrothersBenchBothPlayersCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UBrothersBenchConversationCapability);

	UPROPERTY(EditAnywhere)
	EBrothersBenchID BenchID;

	UPROPERTY(EditInstanceOnly)
	float VistaBlendTime = 20.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0", ClampMax = "6"))
	int FriendshipLevel = 0;

	const float BlendTime = 3.0;
	const float FullScreenDelay = 0.0;
	const float FullScreenBlendDuration = 3.0;
	const float VistaDelay = 0.0;
	const float BlendOutTime = 2.0;

	const float MinFriendshipLevelDistance = 90;
	const float MaxFriendshipLevelDistance = 30;

	TPerPlayer<FBrothersBenchPerPlayerData> PlayerData;
	FHazeAcceleratedVector AccBenchCameraRelativeLocation;
	FVector InitialCameraRelativeLocation;
	EBrothersBenchBlendState BlendState;

	bool bStartConversation = false;
	bool bHasStartedConversation = false;
	bool bHasEndedConversation = false;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioBusMixer AudioBusMixer;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		const float FriendshipLevelAlpha = FriendshipLevel / 6.0;
		const float Distance = Math::Lerp(MinFriendshipLevelDistance, MaxFriendshipLevelDistance, FriendshipLevelAlpha);

		FVector InteractionRelativeLocation = RightInteraction.RelativeLocation;

		InteractionRelativeLocation.Y = Distance;
		RightInteraction.SetRelativeLocation(InteractionRelativeLocation);

		InteractionRelativeLocation.Y = -Distance;
		LeftInteraction.SetRelativeLocation(InteractionRelativeLocation);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialCameraRelativeLocation = BenchCamera.RelativeLocation;

		LeftInteraction.OnEnterBlendedIn.AddUFunction(this, n"OnSitDown");
		LeftInteraction.OnCancelPressed.AddUFunction(this, n"OnGetUp");

		RightInteraction.OnEnterBlendedIn.AddUFunction(this, n"OnSitDown");
		RightInteraction.OnCancelPressed.AddUFunction(this, n"OnGetUp");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(BlendState >= EBrothersBenchBlendState::ProjectionBlending || !IsAnyPlayersSitting())
		{
			AccBenchCameraRelativeLocation.AccelerateTo(FVector::ZeroVector, BlendTime, DeltaTime);
		}
		else
		{
			AHazePlayerCharacter SittingPlayer;
			TryGetSittingPlayer(SittingPlayer);
			auto SittingInteraction = SittingPlayer.IsMio() ? LeftInteraction : RightInteraction;
			AccBenchCameraRelativeLocation.AccelerateTo(FVector(0, SittingInteraction.RelativeLocation.Y, 0), BlendTime, DeltaTime);
		}

		BenchCamera.SetRelativeLocation(InitialCameraRelativeLocation + AccBenchCameraRelativeLocation.Value);

#if EDITOR
		TEMPORAL_LOG(this)
			.Value("BlendState", BlendState)
		;
#endif
	}

	UFUNCTION()
	protected void OnSitDown(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		if(PlayerData[Player].IsSitting())
			return;

		StartSitting(Player, Interaction);

		FBrothersBenchOnPlayerSitDownEventData EventData;
		EventData.Player = Player;
		UBrothersBenchEventHandler::Trigger_OnPlayerSitDown(this, EventData);
	}

	UFUNCTION()
	protected void OnGetUp(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		if(!PlayerData[Player].IsSitting())
			return;

		StopSitting(Player);

		if(bHasStartedConversation)
		{
			FBrothersBenchOnPlayerGetUpEventData EventData;
			EventData.Player = Player;
			UBrothersBenchEventHandler::Trigger_OnPlayerGetUp(this, EventData);
		}
	}

	void StartSitting(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		if(!ensure(!PlayerData[Player].IsSitting()))
			return;

		PlayerData[Player].Interaction = Interaction;
		PlayerData[Player].SitDownTime = Time::GameTimeSeconds;

		if(AreBothPlayersSitting() && AudioBusMixer != nullptr)
			Audio::StartOrUpdateUserStateControlledBusMixer(this, AudioBusMixer, EHazeBusMixerState::FadeIn);
	}

	void StopSitting(AHazePlayerCharacter Player)
	{
		if(!ensure(PlayerData[Player].IsSitting()))
			return;

		PlayerData[Player].Interaction = nullptr;
		PlayerData[Player].SitDownTime = -1;

		if(AudioBusMixer != nullptr)
			Audio::StartOrUpdateUserStateControlledBusMixer(this, AudioBusMixer, EHazeBusMixerState::FadeOut);

	}

	bool AreBothPlayersSitting() const
	{
		for(const FBrothersBenchPerPlayerData& PlayerDatum : PlayerData)
		{
			if(!PlayerDatum.IsSitting())
				return false;
		}

		return true;
	}

	bool IsAnyPlayersSitting() const
	{
		for(const FBrothersBenchPerPlayerData& PlayerDatum : PlayerData)
		{
			if(PlayerDatum.IsSitting())
				return true;
		}

		return false;
	}

	bool TryGetSittingPlayer(AHazePlayerCharacter&out OutSittingPlayer) const
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			const FBrothersBenchPerPlayerData& PlayerDatum = PlayerData[Player];
			if(PlayerDatum.IsSitting())
			{
				OutSittingPlayer = Player;
				return true;
			}
		}

		OutSittingPlayer = nullptr;
		return false;
	}

	bool GetFirstSittingPlayer(AHazePlayerCharacter&out OutSittingPlayer) const
	{
		if(!AreBothPlayersSitting())
			return TryGetSittingPlayer(OutSittingPlayer);

		if(PlayerData[Game::Mio].SitDownTime < PlayerData[Game::Zoe].SitDownTime)
		{
			OutSittingPlayer = Game::Mio;
			return true;
		}
		else
		{
			OutSittingPlayer = Game::Zoe;
			return true;
		}
	}
};