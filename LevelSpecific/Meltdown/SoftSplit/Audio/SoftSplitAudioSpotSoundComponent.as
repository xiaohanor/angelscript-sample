class USoftSplitAudioSpotSoundComponent : USceneComponent
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	UPROPERTY(EditAnywhere)
	float Radius = 500;

	// UPROPERTY()
	// USpotSoundComponent SpotSoundComponent;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent AudioEventToFantasyTransition;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent AudioEventToScifiTransition;

	UHazeAudioComponent SoundDefAudioComponent = nullptr;

	UPROPERTY(EditAnywhere)
	float SecondsBetweenTransitions = 3;

	private float LastPlayedTransition = 0;
	private EHazeWorldLinkLevel LinkedLevel = EHazeWorldLinkLevel::None;
	private UHazeAudioComponent LinkedComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Requires to be in the same level layer as the manager.
		auto Manager = TListedActors<ASoftSplitAudioManager>().GetSingle();
		if (Manager != nullptr)
			Manager.Add(this);

		auto MeshComponent = UStaticMeshComponent::Get(Owner);
		if (MeshComponent != nullptr)
		{
			Radius = MeshComponent.BoundsRadius;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Manager = TListedActors<ASoftSplitAudioManager>().GetSingle();
		if (Manager != nullptr)
			Manager.Remove(this);
	}

	void SetSoundDefAudioComponent(UHazeAudioComponent AudioComponent)
	{
		SoundDefAudioComponent = AudioComponent;
	}

	UHazeAudioComponent GetAudioComponentBasedOnAttachment()
	{
		if (SoundDefAudioComponent != nullptr)
			return SoundDefAudioComponent;

		auto AudioZone = Cast<AAmbientZone>(Owner);
		if (AudioZone != nullptr)
		{
			return AudioZone.AmbienceComponent;
		}

		auto SpotSound = Cast<USpotSoundComponent>(GetAttachParent());
		if (SpotSound != nullptr && SpotSound.Emitter != nullptr)
		{
			return SpotSound.Emitter.GetAudioComponent();
		}

		return nullptr;
	}

	void SetWorldLinkLevel(EHazeWorldLinkLevel NewLevel)
	{
		if (LinkedLevel != EHazeWorldLinkLevel::None && LinkedLevel != NewLevel && LinkedComponent != nullptr)
		{
			auto AnyEmitter = LinkedComponent.GetAnyEmitter();
			if (AnyEmitter != nullptr && Time::GetAudioTimeSince(LastPlayedTransition) > SecondsBetweenTransitions)
			{
				LastPlayedTransition = Time::AudioTimeSeconds;
				
				if (NewLevel == EHazeWorldLinkLevel::Fantasy)
				{
					AnyEmitter.PostEvent(AudioEventToFantasyTransition, PostType = EHazeAudioEventPostType::Local);
				}
				else
				{
					AnyEmitter.PostEvent(AudioEventToScifiTransition, PostType = EHazeAudioEventPostType::Local);
				}
			}
		}

		LinkedLevel = NewLevel;
	}
}

#if EDITOR
class USoftSplitAudioSpotSoundComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USoftSplitAudioSpotSoundComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto SoftSplitComponent = Cast<USoftSplitAudioSpotSoundComponent>(Component);
		
		DrawWireSphere(SoftSplitComponent.WorldLocation, SoftSplitComponent.Radius, FLinearColor::Green, 5);
	}
}

#endif