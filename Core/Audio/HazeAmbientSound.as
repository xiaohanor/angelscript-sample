
struct FHazeAudioEventStruct
{
	UPROPERTY()
	UHazeAudioEvent Event;

	UPROPERTY()
	FName Tag;

	UPROPERTY()
	EHazeAudioEventPostType PostEventType = EHazeAudioEventPostType::Ambience;

	UPROPERTY()
	bool bPlayOnStart;

	UPROPERTY()
	bool bStopOnDestroy;

	UPROPERTY()
	float FadeOutMs;

	UPROPERTY()
	EAkCurveInterpolation FadeOutCurve;

	// NOTE (GK): Do we need this?
	UPROPERTY(NotVisible)
	TArray<int> PlayingIDs;	
}

// Deprecated, only used in testing
class AHazeAmbientSound : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeAudioComponent AudioComponent;
	default AudioComponent.RequestEnable();

	UPROPERTY()
	UHazeAudioEmitter Emitter;

	UPROPERTY(EditInstanceOnly)
	TArray<FHazeAudioEventStruct> Events;

	UPROPERTY(EditInstanceOnly)
	bool TrackPlayerElevationAngle;

	// If empty shared rtpc will be used
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "TrackPlayerElevationAngle"))
	UHazeAudioRtpc ElevationRtpcOverride = nullptr;

	UPROPERTY(EditInstanceOnly)
	bool TrackPlayerAbsoluteElevation;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "TrackPlayerAbsoluteElevation"))
	float ElevationTrackMaxRange = 1000.0;

	// If empty shared rtpc will be used
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "TrackPlayerAbsoluteElevation"))
	UHazeAudioRtpc AbsoluteElevationRtpcOverride = nullptr;

	UPROPERTY(EditInstanceOnly)
	bool bLinkToAudioZone = false;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bLinkToAudioZone"))
	bool bFollowZonePriority = false;

	// If empty shared rtpc will be used
	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bLinkToAudioZone"))
	UHazeAudioRtpc ZoneFadeRtpcOverride = nullptr;

	UPROPERTY(EditInstanceOnly)
	float AttenuationScaling = 1.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "S_Emitter";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Emitter = AudioComponent.GetEmitter(this);
		AudioComponent.SetWorldLocation(GetActorLocation());		

		if (TrackPlayerElevationAngle)
			AudioComponent.GetElevationAngle(true, ElevationRtpcOverride);
		if (TrackPlayerAbsoluteElevation)
			AudioComponent.GetAbsoluteElevation(ElevationTrackMaxRange, 1.0, true, ElevationRtpcOverride);
		if (bLinkToAudioZone)
			AudioComponent.GetZoneOcclusion(bFollowZonePriority, nullptr, true, ZoneFadeRtpcOverride);
		
		for	(FHazeAudioEventStruct& EventsEntry : Events)
		{			
			if (EventsEntry.bPlayOnStart)
			{
				int PlayingID = AudioComponent.PostEvent(EventsEntry.Event,
					PostType = EventsEntry.PostEventType).PlayingID;	
				EventsEntry.PlayingIDs.Add(PlayingID);										
			}
		}

		Emitter.SetAttenuationScaling(AttenuationScaling);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for	(FHazeAudioEventStruct& EventsEntry : Events)
		{
			if (EventsEntry.bStopOnDestroy)
			{
				for	(int PlayingID: EventsEntry.PlayingIDs)
				{
					Emitter.StopPlayingEvent(PlayingID, EventsEntry.FadeOutMs, EventsEntry.FadeOutCurve);
				}
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartAmbientSoundEvent(FName Tag)
	{
		for(FHazeAudioEventStruct& EventStruct : Events)
		{
			if(EventStruct.Tag == Tag)
			{
				int PlayingID = AudioComponent.PostEvent(EventStruct.Event,
					PostType = EventStruct.PostEventType).PlayingID;				
				EventStruct.PlayingIDs.Add(PlayingID);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void StopAmbientSoundEvent(UHazeAudioEvent AudioEvent, bool bStopAllInstances = false)
	{
		for(int i = Events.Num() - 1; i >= 0; i--)
		{
			if(!bStopAllInstances && Events[i].Event != AudioEvent)
				continue;

			if (Events[i].PlayingIDs.Num() > 0)
			{					
				int LastIndex = Events[i].PlayingIDs.Num() - 1;
				int PlayingID = Events[i].PlayingIDs[LastIndex];

				Emitter.StopPlayingEvent(PlayingID, Events[i].FadeOutMs, Events[i].FadeOutCurve, bStopAllInstances);

				Events[i].PlayingIDs.RemoveAt(LastIndex);													
			}
		}
	}
}