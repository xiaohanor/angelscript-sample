struct FSpotSoundEmitterSettings
{
	// Should start immediately?
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bPlayOnStart = true;

	// Attenuation scaling applied to playing sounds
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	float AttenuationScale = 5000;

	// Scaling applied to any game-defined aux sends
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	float AuxSendsMultiplier = 1.0;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	TMap<UHazeAudioRtpc, float> DefaultRtpcs;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	TArray<FHazeAudioNodePropertyParam> NodeProperties;

	// Fade-Out time in seconds to apply if stopped
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	float FadeOut = 0.0;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	FName AttachBoneName = NAME_None;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	TSoftObjectPtr<USceneComponent> SceneComponent = nullptr;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bAllowEventOverride = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent, Meta = (EditCondition = "bAllowEventOverride"))
	UHazeAudioEvent OverrideDefaultEvent = nullptr;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bTrackSoundDirection = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent, Meta = (EditCondition = "bTrackSoundDirection"))
	EHazeAudioSoundDirectionTrackingTarget SoundDirectionTarget = EHazeAudioSoundDirectionTrackingTarget::Listener;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bTrackDistanceToTarget = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent, Meta = (EditCondition = "bTrackDistanceToTarget"))
	EHazeAudioDistanceTrackingTarget DistanceToTarget = EHazeAudioDistanceTrackingTarget::Listener;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bTrackElevationAngle = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent)
	bool bUseSpatialPanning =  false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = SpotSoundComponent, Meta = (EditCondition = "bUseSpatialPanning"))
	EHazePlayer SpatialPanningPlayer = EHazePlayer::Mio;

	bool HasDefaultValues()
	{
		return
			bPlayOnStart == true &&
			AttenuationScale == 5000 &&
			AuxSendsMultiplier == 1.0 &&
			DefaultRtpcs.Num() == 0 &&
			NodeProperties.Num() == 0 &&
			FadeOut == 0 &&
			AttachBoneName == NAME_None &&
			SceneComponent == nullptr &&
			bAllowEventOverride == false &&
			OverrideDefaultEvent == nullptr;
	}
}

UCLASS(HideCategories = "Collision Rendering Cooking Debug")
class USpotSoundComponent : UHazeSpotSoundComponent
{
	UHazeAudioEvent Event;
	FSoundDefReference SoundDef;

	private UHazeAudioComponent AudioComp;
	private bool bWasStoppedOnDisable = false;

	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default SetComponentTickEnabled(false);

	UPROPERTY(EditAnywhere, Category = SpotSoundComponent, Meta = (ShowOnlyInnerProperties))//, Meta = (EditCondition = "UseDefaultSettings()"))
	FSpotSoundEmitterSettings Settings;

	bool UseDefaultSettings() const
	{
		if (Mode != EHazeSpotSoundMode::Multi)
			return true;

		auto MultiComponent = Cast<USpotSoundMultiComponent>(ModeComponent);
		if (MultiComponent != nullptr)
		{
			for(const auto& Setting: MultiComponent.EmitterSettings)
			{
				if (!Setting.bAllowEventOverride)
					return true;
			}
		}

		return false;
	}

	// The audio component uses emitters internally
	UHazeAudioEmitter Emitter;

	bool bAwaitingLinkedActor = false;
	TSoftObjectPtr<AActor> PendingActor = nullptr;

	UPROPERTY(NotVisible, Transient)
	USpotSoundModeComponent ModeComponent = nullptr;

	private AHazeActor WorkaroundOwner = nullptr;

	//
	#if EDITOR

	UFUNCTION(BlueprintOverride)
	void OnModeUpdate()
	{
		if (ModeComponent != nullptr && ModeComponent.SpotMode == Mode)
		{
			return;
		}

		if (GetOwner() == nullptr)
		{
			FName ComponentName;

			// TODO: Delete previous and add component or change subhandle class, If possible attach it to the spotsoundcomponent!
			// Mostly it must be done in c++ backend.
			FAddNewSubobjectParams Params;
			Params.BlueprintContext = Cast<UBlueprint>(GetBlueprint());
			Params.NewClass = LoadModeClass(ComponentName);

			if (!UHazeAudioEditorUtils::AddRemoveSubObjects(this, Params, USpotSoundModeComponent))
			{
				Warning("Failed to create new spotmode component");
			}

			return;
		}

		FScopedTransaction Transaction("Changing Spot Mode");
		Modify();

		if (ModeComponent != nullptr)
		{
			TArray<USpotSoundModeComponent> Childs;
			GetChildrenComponentsByClass(USpotSoundModeComponent, false, Childs);
			for (auto Child : Childs)
			{
				auto ChildMode = Cast<USpotSoundModeComponent>(Child);
				ChildMode.OnModeRemoved(this);
				ChildMode.DestroyComponent(GetOwner());
				ModeComponent = nullptr;
			}
		}

		FName ComponentName;
		auto ModeClass = LoadModeClass(ComponentName);

		if (ModeClass != nullptr)
		{
			if (GetOwner() != nullptr)
			{
				ModeComponent = Cast<USpotSoundModeComponent>(
					Editor::AddInstanceComponentInEditor(GetOwner(), ModeClass, ComponentName)
					);

				ModeComponent.OnModeAdded(this);
				Editor::SelectComponent(ModeComponent);
			}
		}else {
			Editor::ToggleActorSelected(GetOwner());
			Editor::SelectComponent(this);
		}
	}

	#endif

	void GetEmitters(TArray<UHazeAudioEmitter>& OutEmitters) const
	{
		if(Emitter != nullptr)
		{
			OutEmitters.Add(Emitter);
		}
	}

	FName GetEmitterName() const
	{
		#if EDITOR
			return FName(Owner.GetActorLabel(false)+".SpotEmitter");
		#elif TEST
			return FName(Owner.Name.ToString()+".SpotEmitter");
		#else
			return n"SpotEmitter";
		#endif
	}

	void GetAudioComponentAndEmitter(const FSpotSoundEmitterSettings& EmitterSetting, bool bUseAttachment)
	{
		if (AudioComp != nullptr)
			return;
		
		auto Params = FHazeAudioEmitterAttachmentParams();
		Params.EmitterName = GetEmitterName();
		Params.Instigator = this;
		Params.Owner = GetOwner();
		
		if (bUseAttachment)
		{
			auto AttachComp = EmitterSetting.SceneComponent.IsValid() ? EmitterSetting.SceneComponent.Get() : GetAttachParent();
			if (AttachComp == nullptr)
				AttachComp = this;

			Params.Attachment = AttachComp;
			Params.BoneName = EmitterSetting.AttachBoneName;
			Params.Owner = AttachComp.Owner;
		}

		Emitter = Audio::GetPooledEmitter(Params);
		AudioComp = Emitter.GetAudioComponent();

		// Could have been attached to shared component.
		if (AudioComp.EmitterPairs.Num() == 1)
			AudioComp.SetWorldLocation(WorldLocation);
	}

	void ReturnAudioComponentAndEmitter()
	{
		Audio::ReturnPooledEmitter(this, Emitter);
		AudioComp = nullptr;
		Emitter = nullptr;
	}

	void SetPendingActor(TSoftObjectPtr<AActor> AwaitActor)
	{
		bAwaitingLinkedActor = !AwaitActor.IsNull() && AwaitActor.IsPending();
		if (!bAwaitingLinkedActor)
		{
			auto TargetActor = AwaitActor.Get();
			if (TargetActor != nullptr)
			{
				bAwaitingLinkedActor = !TargetActor.HasActorBegunPlay();
			}
		}

		if (bAwaitingLinkedActor)
			PendingActor = AwaitActor;
	}

	private void InternalStart()
	{
		if(Event != nullptr)
		{
			GetAudioComponentAndEmitter(Settings, true);

			SetupEmitter(Settings, Emitter, AudioComp);
			Emitter.PostEvent(Event, PostType = EHazeAudioEventPostType::Ambience);
		}
		else if (SoundDef.SoundDef != nullptr)
		{
			FSpawnSoundDefSpotSoundParams Params;
			Params.SpotParent = Cast<AHazeActor>(GetOwner());

			// Workaround for spots that don't have a hazeactor owner such as volumes.
			if (Params.SpotParent == nullptr)
			{
				if (WorkaroundOwner == nullptr)
				{
					Params.SpotParent = AHazeActor::Spawn(WorldLocation, WorldRotation, FName(f"{Owner.Name.ToString()}_SoundDefActor"), Owner.Level);
					Params.SpotParent.CreateComponent(USceneComponent);
					Params.SpotParent.AttachToActor(Owner);

					// TODO (GK): Fix this
					// Backend will crash without one, yaaaay.
					if (Params.SpotParent.RootComponent == nullptr)
					{
						Params.SpotParent = nullptr;
					}
					WorkaroundOwner = Params.SpotParent;
				}
				else
				{
					Params.SpotParent = WorkaroundOwner;
				}
			}

			Params.SoundDefRef = SoundDef;

			if(bLinkToZone)
			{
				Params.LinkedOcclusionZone = LinkedZone;
			}

			Params.bLinkedZoneFollowRelevance = bLinkToZone && bLinkedZoneFollowRelevance;
			SoundDef::SpawnSoundDefSpot(Params);
		}
	}

	void InternalStop()
	{
		if (Event != nullptr && Event.IsInfinite && Emitter != nullptr)
		{
			Emitter.StopEvent(Event, Settings.FadeOut * 1000);
		}
		
		ReturnAudioComponentAndEmitter();
		// SoundDef will handle itself.
	}

	void SetupEmitter(const FSpotSoundEmitterSettings& EmitterSetting, UHazeAudioEmitter NewEmitter, UHazeAudioComponent AudioComponent)
	{
		NewEmitter.SetAttenuationScaling(EmitterSetting.AttenuationScale);

		auto AudioComponentToSet = AudioComponent != nullptr ? AudioComponent : AudioComp;
		if (bLinkToZone)
			AudioComponentToSet.GetZoneOcclusion(bLinkedZoneFollowRelevance, GetLinkedZone(), true);

		if (EmitterSetting.bTrackSoundDirection)
			AudioComponentToSet.GetSoundDirection(EmitterSetting.SoundDirectionTarget, true);

		if (EmitterSetting.bTrackDistanceToTarget)
			AudioComponentToSet.GetDistanceToTarget(EmitterSetting.DistanceToTarget, true);
		
		if(EmitterSetting.bTrackElevationAngle)
			AudioComponentToSet.GetElevationAngle(true);

		if (EmitterSetting.bUseSpatialPanning)
			NewEmitter.SetSpatialPanning(EmitterSetting.SpatialPanningPlayer);

		for(auto& Pair : EmitterSetting.DefaultRtpcs)
		{
			UHazeAudioRtpc RtpcAsset = Pair.Key;
			NewEmitter.SetRTPC(RtpcAsset, Pair.Value, 0);
		}

		for(auto& Property : EmitterSetting.NodeProperties)
		{
			NewEmitter.SetNodeProperty(Property.ActorMixer, Property.Property, Property.Value);
		}
	}

	// Called externally if we need to update how a SpotSoundComponent uses zone occlusion during runtime
	// Will only be valid if SpotSoundComp is using an event! SoundDefs will need to hande logic as this themselves
	void UpdateZoneOcclusionTracking(UHazeAudioComponent AudioComponent = nullptr, AHazeAudioZone Zone = nullptr, bool bFollowRelevance = true, bool bAutoSetRtpc = false)
	{
		auto AudioComponentToSet = AudioComponent != nullptr ? AudioComponent : AudioComp;
		if(AudioComponentToSet == nullptr)
			return;		
			
		auto ZoneToUse = Zone != nullptr ? Zone : GetLinkedZone();
		if(ZoneToUse == nullptr)
			return;

		AudioComponentToSet.GetZoneOcclusion(bFollowRelevance, ZoneToUse, bAutoSetRtpc);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
#if TEST
		auto DebugManager = AudioDebugManager::Get();
		if (DebugManager != nullptr)
		{
			DebugManager.UnregisterSpot(this);
		}
#endif

		Stop();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if TEST
		auto DebugManager = AudioDebugManager::Get();
		if (DebugManager != nullptr)
		{
			DebugManager.RegisterSpot(this);
		}
#endif
		if(UpdateSoundAsset() == false)
			return;

		if (Mode != EHazeSpotSoundMode::Basic)
		{
			return;
		}

		// Only sounddefs
		if (SoundDef.SoundDef != nullptr)
		{
			SetPendingActor(LinkedMeshOwner);
		}

		if (!Settings.bPlayOnStart)
			return;

		// If we have a PendingActor, delay start until it's loaded.
		if (bAwaitingLinkedActor)
			SetComponentTickEnabled(true);

		Start();
	}

	// Return true if it has a valid asset. Either SD or Event
	bool UpdateSoundAsset() 
	{
		return AssetData.GetSoundAsset(Event, SoundDef) != EHazeSpotSoundAssetType::None;
	}

	void ModeComponentStart()
	{
		if (!Settings.bPlayOnStart)
			return;

		// If we have a PendingActor, delay start until it's loaded.
		if (bAwaitingLinkedActor)
			SetComponentTickEnabled(true);

		Start();
	}

	UFUNCTION(BlueprintCallable)
	void Start()
	{
		// Will be started from tick if true
		if (bAwaitingLinkedActor)
			return;

		if (ModeComponent != nullptr)
		{
			ModeComponent.Start();
		}
		else
		{
			InternalStart();
		}
	}

	UFUNCTION(BlueprintCallable)
	void Stop()
	{
		if (ModeComponent != nullptr)
			ModeComponent.Stop();
		else
			InternalStop();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAwaitingLinkedActor)
		{
			// Might as well try to get the pending actor.
			auto TargetActor = PendingActor.Get();
			// It's loaded
			if (TargetActor != nullptr && TargetActor.HasActorBegunPlay())
			{
				bAwaitingLinkedActor = false;
				// Might be re-enabled by modecomponent.
				SetComponentTickEnabled(false);
				Start();
			}

			return;
		}

		if (ModeComponent == nullptr)
			return;

		ModeComponent.TickMode(DeltaSeconds);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(!bWasStoppedOnDisable)
			return;

		bWasStoppedOnDisable = false;
		// If this was started as a oneshot, then don't retrigger
		// We only re-trigger loops.
		if (Event != nullptr && !Event.IsInfinite)
			return;

		Start();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Stop();
		bWasStoppedOnDisable = true;
	}
}
