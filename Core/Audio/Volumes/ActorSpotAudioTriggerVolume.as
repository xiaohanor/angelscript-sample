class UActorSpotAudioTriggerVolumeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActorBeginOverlap() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActorEndOverlap() {}
}

struct FActorSpotAudioVolumeOverlap
{
	FActorSpotAudioVolumeOverlap(AHazeActor InActor)
	{
		Actor = InActor;
	}

	UPROPERTY()
	AHazeActor Actor = nullptr;

	UHazeAudioEmitter Emitter = nullptr;
	FHazeAudioPostEventInstance EventInstance;	
}

struct FActorSpotAudioTriggerVolumeEventData
{
	UPROPERTY(EditInstanceOnly, Category = "Events")
	UHazeAudioEvent OnEnterEvent = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	UHazeAudioEvent OnExitEvent = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	bool bStopEventOnExit = false;

	UPROPERTY(EditInstanceOnly, Category = "Events", Meta = (EditCondition = bStopEventOnExit, ForceUnits = "ms"))
	int FadeOutTime = 0;
	
	UPROPERTY(EditInstanceOnly, Category = "Properties", meta = (Units = "times"))
	float AttenuationScaling = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	TArray<FHazeAudioNodePropertyParam> NodeProperties;
}

enum ESpotAudioVolumeEmitterFollow
{
	None,
	OverlappedActor,
	SpotVolume
}

UCLASS(ClassGroup = "Audio Volume", HideCategories = "Rendering Physics Collision Debug Actor BrushComponent Cooking")
class AActorSpotAudioTriggerVolume : AVolume
{
	default BrushComponent.CollisionEnabled = ECollisionEnabled::QueryOnly;

	default Shape::SetVolumeBrushColor(this, FLinearColor(0.87, 0.68, 0.05));
	default BrushComponent.LineThickness = 6.0;
	default BrushComponent.CollisionObjectType = ECollisionChannel::ECC_Pawn;
	default SetActorTickEnabled(false);

	private TArray<FActorSpotAudioVolumeOverlap> ActorOverlaps;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<AHazeActor> ActorClass = nullptr;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerOnlyOnce = false;

	UPROPERTY(EditInstanceOnly, Category = "Audio Settings")
	FSpotSoundEmitterSettings Settings;

	UPROPERTY(EditInstanceOnly, Category = "Audio Settings")
	bool bLinkToZone = false;

	UPROPERTY(EditInstanceOnly, Category = "Audio Settings", Meta = (EditCondition = bLinkToZone))
	bool bFollowZoneRelevance = false;

	UPROPERTY(EditInstanceOnly, Category = "Audio Settings", Meta = (EditCondition = bLinkToZone))
	TSoftObjectPtr<AAmbientZone> LinkedAmbientZone = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "SoundDef")
	FSoundDefReference SoundDef;

	UPROPERTY(EditInstanceOnly, Category = "Event", DisplayName = "Event", Meta = (ShowOnlyInnerProperties = true))
	FActorSpotAudioTriggerVolumeEventData EventData;

	UPROPERTY(EditInstanceOnly, Category = "Overlap Settings")
	ESpotAudioVolumeEmitterFollow EmitterFollow = ESpotAudioVolumeEmitterFollow::None;

	UPROPERTY(EditInstanceOnly, Category = "Overlap Settings")
	int MaxNumOverlaps = 0;

	private bool GetbIsUsingEvents() const property
	{
		return SoundDef.SoundDef == nullptr && (EventData.OnEnterEvent != nullptr || EventData.OnExitEvent != nullptr);
	}

	private bool GetActorOverlap(AHazeActor InActor, FActorSpotAudioVolumeOverlap& OutOverlap)
	{
		for(auto Overlap : ActorOverlaps)
		{
			if(InActor == Overlap.Actor)
			{
				OutOverlap = Overlap;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ActorClass == nullptr)
		{
			BrushComponent.CollisionEnabled = ECollisionEnabled::NoCollision;
			return;
		}		
	}

	UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {		
		if(!OtherActor.IsA(ActorClass))
			return;

		if(MaxNumOverlaps > 0 && MaxNumOverlaps < ActorOverlaps.Num())
			return;

		if(bTriggerOnlyOnce && ActorOverlaps.Num() > 0)
			return;

		auto OverlappingActor = Cast<AHazeActor>(OtherActor);	
		auto ActorOverlap = FActorSpotAudioVolumeOverlap(OverlappingActor);		

		USpotSoundComponent ActorSpotSoundComp = USpotSoundComponent::GetOrCreate(OverlappingActor);
		ActorSpotSoundComp.Settings = Settings;
		ActorSpotSoundComp.bLinkToZone = bLinkToZone;
		ActorSpotSoundComp.bLinkedZoneFollowRelevance = bFollowZoneRelevance;	
		ActorSpotSoundComp.SetLinkedZoneObject(LinkedAmbientZone);

		if(bIsUsingEvents)
			ActorSpotSoundComp.AssetData.SetSoundAssetData(EventData.OnEnterEvent);
		else
			ActorSpotSoundComp.AssetData.SetSoundAssetData(SoundDef.SoundDef.Get());

		#if TEST
		UObject AssetToPlay = SoundDef.SoundDef != nullptr ? SoundDef.SoundDef.Get() : EventData.OnEnterEvent;
		if (AssetToPlay != nullptr && ActorSpotSoundComp.UpdateSoundAsset() == false && AudioDebug::IsAnyDebugFlagSet())
		{
			auto SpotActorLabel = AudioDebug::GetActorLabel(this);
			devCheck(false, f"You tried to use '{AssetToPlay}' but the '{SpotActorLabel}'s SpotComponent didn't update it's asset reference!");
		}
		#else
		ActorSpotSoundComp.UpdateSoundAsset();
		#endif

		UPrimitiveComponent LinkedMeshComponent = nullptr;
		switch(EmitterFollow)
		{
			case ESpotAudioVolumeEmitterFollow::None:
			break;
			case ESpotAudioVolumeEmitterFollow::OverlappedActor:
			LinkedMeshComponent = UMeshComponent::Get(OverlappingActor);
			break;
			case ESpotAudioVolumeEmitterFollow::SpotVolume:
			LinkedMeshComponent = BrushComponent;
			break;
		}

		if(LinkedMeshComponent != nullptr)
		{
			USpotSoundPlaneComponent PlaneComp = USpotSoundPlaneComponent::GetOrCreate(OverlappingActor);
			PlaneComp.AttachToComponent(ActorSpotSoundComp);
			PlaneComp.LinkedMeshComponent = LinkedMeshComponent;
			ActorSpotSoundComp.ModeComponent = PlaneComp;
		}

		ActorSpotSoundComp.Start();

		ActorOverlaps.Add(ActorOverlap);
	}

	UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		if(!OtherActor.IsA(ActorClass))
			return;

		auto OverlappingActor = Cast<AHazeActor>(OtherActor);

		FActorSpotAudioVolumeOverlap ActorOverlap;
		if(GetActorOverlap(OverlappingActor, ActorOverlap))
		{
			if(bIsUsingEvents)
			{
				auto SpotSoundComp = USpotSoundComponent::Get(OverlappingActor);
				if(EventData.bStopEventOnExit)
				{
					SpotSoundComp.Stop();
				}

				if(EventData.OnExitEvent != nullptr)
				{
					SpotSoundComp.AssetData.SetSoundAssetData(EventData.OnExitEvent);
					#if TEST
					if (SpotSoundComp.UpdateSoundAsset() == false && AudioDebug::IsAnyDebugFlagSet())
					{
						auto SpotActorLabel = AudioDebug::GetActorLabel(this);
						devCheck(false, f"You tried to play '{EventData.OnExitEvent}' but the '{SpotActorLabel}'s SpotComponent didn't update it's asset reference!");
					}
					#else
					SpotSoundComp.UpdateSoundAsset();
					#endif
					SpotSoundComp.Start();
				}
			}
			else if(SoundDef.SoundDef != nullptr)
			{
				// TODO: Ideally we would not remove the SoundDef, instead block it by Tag and re-enable it if the same actor enters again
				OverlappingActor.RemoveSoundDef(SoundDef);
			}

			ActorOverlaps.Remove(ActorOverlap);

			if(bTriggerOnlyOnce)
				BrushComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}	
}