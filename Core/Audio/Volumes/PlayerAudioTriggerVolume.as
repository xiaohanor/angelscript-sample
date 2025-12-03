enum ESoundPositionType
{
	OnPlayer,
	VolumeCenter
}

UCLASS(HideCategories = "Rendering Physics Collision Debug Actor Cooking")
class APlayerAudioTriggerVolume : APlayerAudioVolumeBase
{
	UPROPERTY(EditInstanceOnly, Category = "Assets")
	TArray<FHazeSpotSoundAssetData> OnEnterAssets;

	UPROPERTY(EditInstanceOnly, Category = "Assets")
	TArray<FHazeSpotSoundAssetData> OnExitAssets;
	
	UPROPERTY(EditInstanceOnly, Category = "Properties")
	ESoundPositionType Position = ESoundPositionType::OnPlayer;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	bool bStopEventsOnExit = false;

	UPROPERTY(EditInstanceOnly, Category = "Properties", meta = (EditCondition = "bStopEventsOnExit", bEditConditionHides = "true", ForceUnits = "seconds"))
	float FadeoutTimeOnStop = 0.1;

	private TArray<UHazeAudioEvent> OnEnterEvents;
	private TArray<UHazeAudioEvent> OnExitEvents;

	private TArray<FSoundDefReference> OnEnterSoundDefs;
	private TArray<FSoundDefReference> OnExitSoundDefs;

	private TArray<int> TrackedPlayingIDs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TrackedPlayingIDs.Empty();

		for(auto& AssetData : OnEnterAssets)
		{
			UHazeAudioEvent EventAsset = nullptr;
			FSoundDefReference SoundDefData;
			AssetData.GetSoundAsset(EventAsset, SoundDefData);

			if(EventAsset != nullptr)
			{
				OnEnterEvents.Add(EventAsset);
			}
			else
			{
				OnEnterSoundDefs.Add(SoundDefData);	
			}
		}

		for(auto& AssetData : OnExitAssets)
		{
			UHazeAudioEvent EventAsset = nullptr;
			FSoundDefReference SoundDefData;
			AssetData.GetSoundAsset(EventAsset, SoundDefData);

			if(EventAsset != nullptr)
			{
				OnExitEvents.Add(EventAsset);
			}
			else
			{
				OnExitSoundDefs.Add(SoundDefData);	
			}
		}
	}
	
	void PlayOnEnter(AHazePlayerCharacter Player) override
	{
		for(auto& EnterEvent : OnEnterEvents)
		{	
			FHazeAudioPostEventInstance EventInstance;

			if(Position == ESoundPositionType::VolumeCenter)
				EventInstance = VolumeEmitter.PostEvent(EnterEvent, PostType = EHazeAudioEventPostType::Ambience);
			else
				EventInstance = Player.PlayerAudioComponent.PostEvent(EnterEvent, PostType = EHazeAudioEventPostType::Ambience);

			if(bStopEventsOnExit && EventInstance.PlayingID >= 0)
				TrackedPlayingIDs.Add(EventInstance.PlayingID);
		}			

		for(auto& EnterSoundDefRef : OnEnterSoundDefs)
		{
			FTransform SoundPosition = Position == ESoundPositionType::OnPlayer ? Player.GetActorTransform() : GetActorTransform();
			EnterSoundDefRef.SpawnSoundDefOneshot(this, SoundPosition);
		}
	}

	void PlayOnExit(AHazePlayerCharacter Player) override
	{
		Super::PlayOnExit(Player);
		
		for(int PlayingID : TrackedPlayingIDs)
		{
			VolumeEmitter.StopPlayingEvent(PlayingID, FadeoutTimeOnStop);
		}

		for(auto& ExitEvent : OnExitEvents)
		{
			if(Position == ESoundPositionType::VolumeCenter)
				VolumeEmitter.PostEvent(ExitEvent, PostType = EHazeAudioEventPostType::Ambience);
			else
				Player.PlayerAudioComponent.PostEvent(ExitEvent, PostType = EHazeAudioEventPostType::Ambience);
		}

		for(auto& ExitSoundDefRef : OnExitSoundDefs)
		{
			FTransform SoundPosition = Position == ESoundPositionType::OnPlayer ? Player.GetActorTransform() : GetActorTransform();
			ExitSoundDefRef.SpawnSoundDefOneshot(this, SoundPosition);
		}
	}
}

class UPlayerAudioTriggerVolumeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = APlayerAudioTriggerVolume;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideCategory(n"BrushSettings");
		EditCategory(n"VolumeSettings");
		AddDefaultPropertiesFromOtherCategory(n"VolumeSettings", n"BrushSettings");
	}
}