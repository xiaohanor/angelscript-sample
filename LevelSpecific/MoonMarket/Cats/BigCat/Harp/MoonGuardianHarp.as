event void MoonMarketOnHarpNoteSucceededEvent();
event void MoonMarketOnStartedPlayingHarpEvent(UMoonGuardianHarpPlayingComponent Player);
event void MoonMarketOnStoppedPlayingHarpEvent();
event void MoonMarketOnHarpFailedEvent();

class AMoonGuardianHarp : AMoonMarketInteractableActor
{
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Lantern);
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Harp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY()
	UHazeCapabilitySheet Sheet;

	UPROPERTY(BlueprintReadOnly)
	MoonMarketOnHarpNoteSucceededEvent OnSucceess;
	
	UPROPERTY(BlueprintReadOnly)
	MoonMarketOnHarpFailedEvent OnFail;

	MoonMarketOnStartedPlayingHarpEvent OnStartedPlaying;
	MoonMarketOnStoppedPlayingHarpEvent OnStoppedPlaying;

	bool bHarpPlaying;
	private FHazeAudioID HarpMusicPanningRTPC("Rtpc_Music_MoonMarket_GuardianCat_Harp_Strum_SpeakerPanning");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		OnFail.AddUFunction(this, n"OnFailedNote");
		OnSucceess.AddUFunction(this, n"OnSuccess");
	}

	UFUNCTION()
	private void OnSuccess()
	{
		UMoonGuardianHarpEventHandler::Trigger_OnSuccessfulNote(this, FMoonMarketInteractingPlayerEventParams(InteractingPlayer));
	}

	UFUNCTION()
	private void OnFailedNote()
	{
		UMoonGuardianHarpEventHandler::Trigger_OnFailedNote(this, FMoonMarketInteractingPlayerEventParams(InteractingPlayer));
	}

	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		Player.StartCapabilitySheet(Sheet, this);
		Player.ActivateCamera(CameraComp, 2.0, this);
		UMoonGuardianHarpPlayingComponent::Get(Player).StartPlaying(this);
		OnStartedPlaying.Broadcast(UMoonGuardianHarpPlayingComponent::Get(Player));

		float PanningValue = Player.IsMio() ? -1 : 1;
		AudioComponent::SetGlobalRTPC(HarpMusicPanningRTPC, PanningValue * Audio::GetPanningRuleMultiplier());
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		InteractingPlayer.StopCapabilitySheet(InteractComp.InteractionSheet, this);
		InteractingPlayer.DeactivateCameraByInstigator(this);
		UMoonGuardianHarpPlayingComponent::Get(InteractingPlayer).StopPlaying();
		Super::OnInteractionStopped(InteractingPlayer);
		OnStoppedPlaying.Broadcast();
	}
};