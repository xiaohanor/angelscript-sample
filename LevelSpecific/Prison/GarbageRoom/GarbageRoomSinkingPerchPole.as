UCLASS(Abstract)
class AGarbageRoomSinkingPerchPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	USceneComponent PoleRoot;

	UPROPERTY(DefaultComponent, Attach = PoleRoot)
	UStaticMeshComponent PoleMesh;

	UPROPERTY(DefaultComponent, Attach = PoleRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 2500.0;

	UPROPERTY(EditAnywhere)
	bool bSink = true;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent OnPoleEnterEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent OnPoleExitEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FHazeAudioFireForgetEventParams Params;
	default Params.AttachComponent = PoleRoot;

	bool bPlayerOnPole = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartedPerching");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StoppedPerching");
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (bSink)
		{
			bPlayerOnPole = true;
			TranslateRoot.ApplyImpulse(TranslateRoot.WorldLocation, -FVector::UpVector * 200.0);

			if(OnPoleEnterEvent != nullptr)
			{
				const float SpeakerPanningValue = Player.IsMio() ? -1.0 : 1.0;
				FHazeAudioRTPCParam SpeakerPanningRtpcParam = FHazeAudioRTPCParam(Audio::Rtpc_SpeakerPanning_LR, SpeakerPanningValue);
				Params.RTPCs.Add(SpeakerPanningRtpcParam);

				AudioComponent::PostFireForget(OnPoleEnterEvent, Params);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void StoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (bSink)
		{
			bPlayerOnPole = false;

			if(OnPoleExitEvent != nullptr)
			{
				const float SpeakerPanningValue = Player.IsMio() ? -1.0 : 1.0;
				FHazeAudioRTPCParam SpeakerPanningRtpcParam = FHazeAudioRTPCParam(Audio::Rtpc_SpeakerPanning_LR, SpeakerPanningValue);
				Params.RTPCs.Add(SpeakerPanningRtpcParam);

				AudioComponent::PostFireForget(OnPoleExitEvent, Params);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayerOnPole)
			TranslateRoot.ApplyForce(TranslateRoot.WorldLocation + (FVector::UpVector * 50.0), -FVector::UpVector * 100.0);
	}
}