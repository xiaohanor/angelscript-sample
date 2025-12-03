
enum EAmbientZoneCurve
{
	Linear,
	Exponential,
	Logarithmic
}

namespace AmbientRTPC
{
	const FHazeAudioID AmbZoneFade = FHazeAudioID("Rtpc_Shared_AmbientZone_Fade");
	const FHazeAudioID AmbZonePanning = FHazeAudioID("Rtpc_Shared_AmbientZone_Panning");
	// const FHazeAudioID ListenerProximityBoostCompensation = FHazeAudioID("SOME RTPC");
};

struct FRandomSpotSoundRuntimeData
{
	UPROPERTY()
	FHazeAudioPostEventInstance EventInstance;

	UPROPERTY()
	FVector PlayingLocation;
	
	UPROPERTY()
	float VerticalOffset = 0.;
	
	UPROPERTY()
	float HorizontalOffset = 0.;
	
	UPROPERTY()
	float CurrentTime = 0.;
	
	UPROPERTY()
	float NextTime = 0.;
}

UCLASS(Meta = (NoSourceLin), HideCategories = "Collision Rendering Cooking Debug")
class AAmbientZone : AHazeAudioZone
{
	access PrivateAndDebug = private, UAudioDebugZones;

	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ZoneType = EHazeAudioZoneType::Ambience;
	default BrushComponent.SetCollisionProfileName(n"AudioZone");

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "ZoneAmbience";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif

	UPROPERTY(EditInstanceOnly, Category="Audio")
	bool bLimitRandomSpotsToZoneBounds = true;

	UPROPERTY(EditInstanceOnly, Category="Audio")
	bool bLimitRandomSpotsToPlayerView = false;

	UPROPERTY(EditInstanceOnly, Category="Audio", Meta = (EditCondition="bLimitRandomSpotsToPlayerView"))
	EHazePlayer RandomSpotsPlayerViewport = EHazePlayer::Mio;

	UPROPERTY(EditInstanceOnly, Category="Audio")
	float SendLevelOverride = 1;

	UPROPERTY(EditInstanceOnly, Category="Audio")
	UHazeAudioAuxBus ReverbBusOverride = nullptr;

	// In dB
	UPROPERTY(EditInstanceOnly, Category="Audio")
	float PlayerVoGameAuxSendVolume = 0;

	// In dB
	UPROPERTY(EditInstanceOnly, Category="Audio")
	float PlayerVoUserAuxSendVolume0 = 0;

	// By default we will apply it on \Actor-Mixer Hierarchy\Default Work Unit\Amix_Master\VO\Amix_VO
	UPROPERTY(EditInstanceOnly, Category="Audio")
	UHazeAudioActorMixer VoAmixForGameAuxSendVolumeOverride = nullptr;
	
	access:PrivateAndDebug
	TArray<FRandomSpotSoundRuntimeData> ActiveSpots;

	const float MoveToZoneFadeTargetSpeed = 2.25;
	private float LastPanningValue = -1;
	
	private bool bActivatingZone = false;
	UHazeAudioComponent AmbienceComponent = nullptr;

	float GetZoneRtpcTarget()
	{
		return ZoneFadeTargetValue;
	}

	UFUNCTION(BlueprintOverride)
	float GetSendLevel()
	{
		if (!Math::IsNearlyEqual(SendLevelOverride, 1))
			return SendLevelOverride;

		if (ZoneAsset != nullptr)
			return ZoneAsset.SendLevel;

		return 1;
	}

	UFUNCTION(BlueprintOverride)
	UHazeAudioAuxBus GetReverbBus()
	{
		if (ReverbBusOverride != nullptr)
			return ReverbBusOverride;

		if (ZoneAsset != nullptr)
			return ZoneAsset.ReverbBus;

		return nullptr;
	}

	UHazeAudioEmitter GetOrPoolAudioComponent()
	{
		if (AmbienceComponent != nullptr)
			return AmbienceComponent.GetEmitter(this);

		FHazeAudioPoolComponentParams Params;
		Params.bReverbEnabled = false;
		
		AmbienceComponent = Audio::GetPooledAudioComponent(Params);
		AmbienceComponent.RequestEnable();
		AmbienceComponent.SetWorldLocation(BrushComponent.GetBoundsOrigin());

		return AmbienceComponent.GetEmitter(this);
	}

	// NOTE: We might recalculate panning and listeners when connected to portal zone
	UFUNCTION(BlueprintOverride)
	void OnUpdatedListenerOverlaps(bool bAddedListener)
	{
		if (ZoneAsset == nullptr)
			return;

		// If we don't have a amb component yet then get it and post
		if (bAddedListener && AmbienceComponent == nullptr)
			GetOrPoolAudioComponent().PostEvent(ZoneAsset.QuadEvent, PostType = EHazeAudioEventPostType(EHazeAudioEventPostType::Ambience | EHazeAudioEventPostType::Local));
		
		// NOTE: Before we used to assign the listeners in range to be assigned
		// as listeners but, this results in a dB increase when two listeners 
		// are present. Instead we now treat them as any other non-spatial sound.
		// By using default listeners.
		// UpdateAmbienceListeners(ListenersInRange);
	}

	// void UpdateAmbienceListeners(const TArray<UHazeAudioListenerComponent>& ListenersInRange)
	// {
	// 	ensure(AmbienceComponent != nullptr);

	// 	TArray<UHazeAudioObject> NewListeners;
	// 	for (UHazeAudioListenerComponent NearbyListener : ListenersInRange)
	// 		NewListeners.Add(NearbyListener);
	// 	AmbienceComponent.SetListeners(NewListeners);
	// }

	void UpdatePanning(const float& PanningValue)
	{
		if(PanningValue == LastPanningValue)
			return;

		LastPanningValue = PanningValue;

		if (AmbienceComponent == nullptr)
			return;

		auto Emitter = AmbienceComponent.GetAnyEmitter();
		if (Emitter == nullptr)
		 	return;

		Emitter.SetRTPC(AmbientRTPC::AmbZonePanning, LastPanningValue, 0.0);
	}

	float GetPanningValue() const
	{
		return LastPanningValue;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AudioZone::OnBeginPlay(this);

		if (RandomSpots != nullptr)
		{
			ActiveSpots.SetNum(RandomSpots.SpotSounds.Num());

			for (int i=0; i < ActiveSpots.Num(); ++i)
			{
				ActiveSpots[i].NextTime = Math::RandRange(RandomSpots.SpotSounds[i].MinRepeatRate, RandomSpots.SpotSounds[i].MaxRepeatRate);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Audio::ReturnPooledAudioComponent(AmbienceComponent);
		AmbienceComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void SetZoneRTPC(float Value, float PowerOfOverride)
	{
		float CurveValue = 0;

		// Can be overriden by portal zones.
		if (PowerOfOverride != 0)
		{
			CurveValue = Math::Pow(Value, PowerOfOverride);
			// PrintToScreen(GetActorLabel() + ", Relevance: " + Value +  ", CurveValue: " + CurveValue);
		}
		else 
			CurveValue = Math::Pow(Value, ZoneRTPCCurvePower);

		if(ZoneFadeTargetValue == CurveValue && IsActorTickEnabled())
			return;

		ZoneFadeTargetValue = CurveValue;

		if (!IsActorTickEnabled())
		{
			ZoneRTPCValue = ZoneFadeTargetValue;
			if(AmbienceComponent != nullptr)
				AmbienceComponent.GetAnyEmitter().SetRTPC(AmbientRTPC::AmbZoneFade, ZoneRTPCValue, 0);
		}					
	}
	
	void UpdateRandomSpots(float DeltaSeconds)
	{
		if (ListenerOverlaps.Num() <= 0)
			return;

		if (RandomSpots == nullptr)
			return;	
		
		// NOTE: If we have listeners and the quad is active post random spots as well.
		// 		 They will be faded based on the same rtpc as the quad.
		// 		 Keeping below as is, if this behaviour will change again.
		// bool bShouldUpdateRandomSpotsAsset = false;
		// for(UHazeAudioListenerComponent Listener : ListenersInAttenuationRange)
		// {
		// 	if(Listener.GetPrioritizedZone() == this)
		// 	{
		// 		bShouldUpdateRandomSpotsAsset = true;
		// 		break;
		// 	}
		// }

		// if(!bShouldUpdateRandomSpotsAsset)
		// 	return;	

		// They will all be silent.
		if (ZoneRTPCValue == 0)
			return;

		#if EDITOR
		// If the asset is updated, update size of active spots
		if (RandomSpots.SpotSounds.Num() != ActiveSpots.Num())
		{
			// We don't really care in this case to preserve data or correct order.
			ActiveSpots.SetNum(RandomSpots.SpotSounds.Num());
		}
		#endif
		
		for (int i=0; i < ActiveSpots.Num(); ++i)
		{
			const auto& RandomSpot = RandomSpots.SpotSounds[i];

			if (RandomSpot.Event == nullptr)
				continue;
			
			auto& ActiveSpot = ActiveSpots[i];
			ActiveSpot.CurrentTime += DeltaSeconds;
			if (ActiveSpot.CurrentTime < ActiveSpot.NextTime)
				continue;

			ActiveSpot.CurrentTime = 0;
			ActiveSpot.NextTime = Math::RandRange(RandomSpot.MinRepeatRate, RandomSpot.MaxRepeatRate);

			const float VerticalOffset = Math::RandRange(RandomSpot.MinHeight, RandomSpot.MaxHeight);
			const float HorizontalOffset = Math::RandRange(RandomSpot.MinDistance, RandomSpot.MaxDistance);

			FVector VerticalOffsetPos = FVector::UpVector * VerticalOffset;
			FVector HorizontalOffsetPos = Math::GetRandomPointInCircle_XY() * HorizontalOffset;
			FVector Location = HorizontalOffsetPos + VerticalOffsetPos;

			ActiveSpot.VerticalOffset = VerticalOffset;
			ActiveSpot.HorizontalOffset = HorizontalOffset;

			FVector ListenerLocation;
			if (ListenerOverlaps.Num() == 1 || Math::RandBool())
			{
				ListenerLocation = ListenerOverlaps[0].Object.GetWorldLocation();
			}
			else
			{
				ListenerLocation = ListenerOverlaps[1].Object.GetWorldLocation();
			}

			Location += ListenerLocation;

			// If the zone is larger than the viewport.
			if (bLimitRandomSpotsToPlayerView)
			{
				auto Player = Game::GetPlayer(RandomSpotsPlayerViewport);

				FVector2D ScreenPos;
				SceneView::ProjectWorldToScreenPosition(Player, Location, ScreenPos);

				if(ScreenPos.Min < 0 || ScreenPos.Max > 1)
				{
					ScreenPos.X = Math::Clamp(ScreenPos.X, 0, 1);
					ScreenPos.Y = Math::Clamp(ScreenPos.Y, 0, 1);

					FVector OutOrigin, OutDirection;
					SceneView::DeprojectScreenToWorldInView_Absolute(Player, ScreenPos, OutOrigin, OutDirection);
					
					Location = OutOrigin + (Location - OutOrigin).ProjectOnToNormal(OutDirection);
				}
			}

			if (bLimitRandomSpotsToZoneBounds)
			{
				// Make sure it's inside the box
				FVector SafeLocation;
				float DistanceFromZone = BrushComponent.GetClosestPointOnCollision(Location, SafeLocation);
				if (DistanceFromZone > 0)
					Location = SafeLocation;
			}

			FHazeAudioFireForgetEventParams Params;
			Params.RTPCs.Add(FHazeAudioRTPCParam(AmbientRTPC::AmbZoneFade, ZoneRTPCValue));
			Params.RTPCs.Add(FHazeAudioRTPCParam(AmbientRTPC::AmbZonePanning, LastPanningValue));
			Params.Transform.SetLocation(Location);
			ActiveSpot.PlayingLocation = Location;

			#if TEST
			// If we want to have a complete debug of random spots we need to track the fireforget sounds
			FOnHazeAudioPostEventCallback OnRandomSpotEndCallback;
			OnRandomSpotEndCallback.BindUFunction(this, n"OnRandomSpotEnd");
			#endif

			auto RandomsSpotEventInstance = AudioComponent::PostFireForget(
				RandomSpot.Event, 
				Params,
				PostType = EHazeAudioEventPostType(EHazeAudioEventPostType::Ambience | EHazeAudioEventPostType::Local)
				#if TEST
				, Callback = OnRandomSpotEndCallback
				#endif
				);

			#if TEST
			ActiveSpot.EventInstance = RandomsSpotEventInstance;
			if (AudioDebug::IsEnabled(EHazeAudioDebugType::Zones))
			{
				Debug::DrawDebugPoint(Location, 50.0, FLinearColor::Purple, 15.0);

				if (RandomsSpotEventInstance.PlayingID == 0)
				{
					PrintToScreen(f"Failed to Spawn Random Spot Sound: {RandomSpot.Event}", 5.0);
				}
			}
			#endif
		}
	}

	UFUNCTION()
	void OnRandomSpotEnd(EAkCallbackType CallbackType, UHazeAudioCallbackInfo CallbackInfo)
	{
#if TEST
		UHazeAudioEventCallbackInfo EventCallbackInfo = Cast<UHazeAudioEventCallbackInfo>(CallbackInfo);
		if (EventCallbackInfo == nullptr)
			return;

		for(auto& RandomSpotData : ActiveSpots)
		{
			if(RandomSpotData.EventInstance.PlayingID == EventCallbackInfo.PlayingID)
			{
				RandomSpotData.EventInstance = Audio::GetEmptyEventInstance();
			}
		}
#endif
	}

	private void UpdateZoneRtpcToTarget(const float& DeltaSeconds)
	{
		if (MoveZoneRtpcToTarget(GetZoneRtpcTarget(), DeltaSeconds))
		{
			if(AmbienceComponent != nullptr)
				AmbienceComponent.GetAnyEmitter().SetRTPC(AmbientRTPC::AmbZoneFade, ZoneRTPCValue, 0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateZoneRtpcToTarget(DeltaSeconds);
		// UpdateListeners();
		UpdateRandomSpots(DeltaSeconds);

		if (!bShouldTick && ZoneRTPCValue == GetZoneRtpcTarget())
		{
			SetZoneTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnZoneTickEnabled(bool bTickEnabled)
	{
		// No need to get a new component until a OnAdded logic is run.
		if (!bTickEnabled)
		{
			Audio::ReturnPooledAudioComponent(AmbienceComponent);
			AmbienceComponent = nullptr;
		}
	}
}
