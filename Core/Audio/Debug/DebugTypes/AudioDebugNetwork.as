
struct FAudioDebugRtpcIgnore
{
	TSet<FString> Rtpcs;

	FAudioDebugRtpcIgnore()
	{
		Rtpcs.Add("Rtpc_Shared_ObjectAzimuth_Horizontal_Vertical_Combined");
		Rtpcs.Add("Rtpc_Shared_ObjectAzimuth_Horizontal_Combined");
		Rtpcs.Add("Rtpc_Shared_ObjectAzimuth_Vertical_Combined");

		Rtpcs.Add("Rtpc_Shared_ObjectVelocity_Angular");
		Rtpcs.Add("Rtpc_Shared_ObjectVelocity_Angular_Delta");
		Rtpcs.Add("Rtpc_Shared_ObjectVelocity_Linear");
		Rtpcs.Add("Rtpc_Shared_ObjectVelocity_Linear_Delta");

		Rtpcs.Add("Rtpc_Shared_ObjectElevation_Absolute");
		Rtpcs.Add("Rtpc_Shared_ObjectElevation_Angle");
		Rtpcs.Add("Rtpc_Shared_ObjectElevation_Delta");

		Rtpcs.Add("Rtpc_Shared_Distance");
		Rtpcs.Add("Rtpc_Shared_SoundDirection");

		Rtpcs.Add("Rtpc_Shared_ObjectRotation_Tilt");
		Rtpcs.Add("Rtpc_Shared_ObjectRotation_Yaw");
		Rtpcs.Add("Rtpc_Shared_ObjectRotation_Roll");

		Rtpcs.Add("Rtpc_Shared_EnvironmentType");
		Rtpcs.Add("Rtpc_Shared_AmbientZone_Fade");

		Rtpcs.Add("Rtpc_SpeakerPanning_LR");
		Rtpcs.Add("Rtpc_VO_Player_InGame_Panning_LR_Mio");
		Rtpcs.Add("Rtpc_VO_Player_InGame_Panning_LR_Zoe");

		Rtpcs.Add("Rtpc_Shared_Camera_InWater");
		Rtpcs.Add("Rtpc_Shared_Object_InWater");
		Rtpcs.Add("Rtpc_Shared_Player_InWaterness");

		Rtpcs.Add("Rtpc_Shared_Player_IsMio_IsZoe");
	}
}

struct FAudioDebugNetworkEventData
{
	// 
	const UHazeAudioEvent Event;

	//
	float64 LocalStart;
	float64 RemoteStart;

	float64 LocalStop;
	float64 RemoteStop;

	//
	float64 DiscoveredTime = Time::PlatformTimeSeconds;
	bool bProcessed = true;

	bool IsFinished()
	{
		if (LocalStart != 0)
			return LocalStop != 0;

		if (RemoteStart != 0)
			return RemoteStop != 0;

		return true;
	}

	float64 StopTime()
	{
		if (LocalStop != 0)
			return LocalStop;

		if (RemoteStop != 0)
			return RemoteStop;

		return DiscoveredTime;
	}
}

struct FAudioDebugNetworkRtpcData
{
	float LocalValue;
	float RemoteValue;
	
	float64 DiscoveredTime = Time::PlatformTimeSeconds;
	bool bProcessed = true;
}

struct FAudioDebugNetworkActorData
{
	UHazeAudioEmitter Local;
	UHazeAudioEmitter Remote;

	UObject EmitterOwner;
	AActor LocalOwner;
	AActor RemoteOwner;

	TMap<int32, FAudioDebugNetworkEventData> Events;
	TMap<FString, FAudioDebugNetworkRtpcData> Rtpcs;

	TMap<UHazeAudioEvent, FAudioDebugNetworkEventData> OutOfSyncEvents;
	TMap<FString, FAudioDebugNetworkRtpcData> OutOfSyncRtpcs;
}

struct FAudioDebugNetworkEventMissingData
{
	FName OwnerID;
	FString EventName;
}

struct FAudioDebugNetworkRtpcMissingData
{
	FName OwnerID;
	FString RtpcName;
}

class UAudioDebugNetwork : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Network; }
	
	FString GetTitle() override
	{
		return "Network";
	}

	bool DebugEnabled() override 
	{ 
		return bIsWorldDebugEnabled || bIsViewportDebugEnabled; 
	}

	default bUseCustomDrawing = true;

	TMap<FName, FAudioDebugNetworkActorData> TrackingByOwner;
	FAudioDebugRtpcIgnore RtpcIgnore;

	void OnViewToggled() override
	{
		TrackingByOwner.Reset();
	}

	void Shutdown() override
	{
		TrackingByOwner.Reset();		
	}

	void DrawCustom(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& MiosSection,
					const FHazeImmediateSectionHandle& ZoesSection) override
	{
		Super::DrawCustom(DebugManager, MiosSection, ZoesSection);
		
		#if !EDITOR
		ZoesSection.Text("Only supports simulated network").Color(FLinearColor::Red);
		return;
		#else
		if (Network::IsGameNetworked() == false)
			return;

		if (DebugManager.World.HasControl() == false)
			return;

		DrawInMenu(DebugManager, MiosSection, ZoesSection);

		Evaluate(DebugManager, MiosSection, ZoesSection);
		#endif
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		#if !EDITOR
		Section.Text("Only supports simulated network").Color(FLinearColor::Red);
		return;
		#else
		if (Network::IsGameNetworked() == false)
			return;

		if (DebugManager.World.HasControl() == false)
			return;

		DrawInMenu(DebugManager, Section, Section);

		if (!bUseViewportDrawer)
		{
			Evaluate(DebugManager, Section, Section);
		}

		#endif
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		#if !EDITOR
		return;
		#else
		IterateData(DebugManager);
		#endif
	}

#if EDITOR

	void IterateData(UAudioDebugManager DebugManager)
	{
		if (Network::IsGameNetworked() == false)
			return;

		if (DebugManager.World.HasControl() == false)
			return;

		// So we need to have both control and remote side to debug this.
		auto OtherWorld = Debug::GetPIENetworkOtherSideForDebugging(DebugManager.World);
		UAudioDebugManager OtherDebug = nullptr;
		if (OtherWorld != nullptr)
		{
			FAngelscriptGameThreadScopeWorldContext Context(OtherWorld);
			OtherDebug = Cast<UAudioDebugManager>(UHazeAudioDebugManager::Get());
		}

		if (OtherDebug == nullptr)
			return;

		auto ControlComps = DebugManager.GetRegisteredComponents();
		auto RemoteComps = OtherDebug.GetRegisteredComponents();

		for (auto AudioComponent: ControlComps)
			IterateEmitters(DebugManager, AudioComponent.EmitterPairs, true);

		for (auto AudioComponent: RemoteComps)
			IterateEmitters(DebugManager, AudioComponent.EmitterPairs, false);
	}

	bool IgnoreEmitter(UHazeAudioEmitter Emitter)
	{
		return Emitter.GetAudioComponent() == nullptr && Emitter.Name == n"GlobalEmitter";
	}

	bool IgnoreEvent(const FHazeAudioPostEventInstance& EventInstance) const
	{
		const auto EventName = EventInstance.EventName();
		if (EventName.StartsWith("Player_Character_"))
			return true;

		if (EventName.StartsWith("Play_VO_EFT_"))
			return true;

		if (EventName.StartsWith("Play_Character_Movement_"))
			return true;

		return (int(EventInstance.PostType) & (int(EHazeAudioEventPostType::Ambience) | int(EHazeAudioEventPostType::Animation) | int(EHazeAudioEventPostType::UI))) != 0;
	}
	
	bool IgnoreRtpc(const FString& RtpcName) const
	{
		if(RtpcIgnore.Rtpcs.Contains(RtpcName))
			return true;

		return false;
	}

	FName TryGetOwnerID(const FOwnerEmitterPair&in EmitterPair, AActor&out OutOwner)
	{
		auto Emitter = EmitterPair.Emitter;

		if (Emitter.GetAudioComponent() == nullptr)
			return Emitter.GetName();

		auto AudioComponent = Emitter.GetAudioComponent();
		
		AActor Owner = nullptr;
		if (AudioComponent.IsAPooledObject())
		{
			if (AudioComponent.AttachParent != nullptr)
				Owner = AudioComponent.AttachParent.Owner;
			else
				Owner = AudioComponent.Owner;
		}
		else
		{
			auto SoundDefOwner = Cast<UHazeSoundDefBase>(EmitterPair.Owner);
			if (SoundDefOwner != nullptr)
			{
				Owner = SoundDefOwner.HazeOwner;
			}
			else
			{
				Owner = AudioComponent.Owner;
			}
		}

		// The emitter index might not be the same on the remote, so remove it.
		auto EmitterName = Emitter.Name.ToString();
		auto Index = EmitterName.Find("Emitter_", ESearchCase::IgnoreCase, ESearchDir::FromEnd);

		if (Index != -1)
			EmitterName = EmitterName.LeftChop(EmitterName.Len() - (Index + 7));
		
		auto ActorName = Owner.Name.ToString();

		if (!Owner.HasControl())
		{
			auto OtherSideOwner = Cast<AActor>(Debug::GetPIENetworkOtherSideForDebugging(Owner));
			if (OtherSideOwner != nullptr)
			{
				ActorName = OtherSideOwner.Name.ToString();
			}
		}

		OutOwner = Owner;
		return FName(f"{ActorName}_{EmitterName}");
	}

	void IterateEmitters(UAudioDebugManager DebugManager, const TArray<FOwnerEmitterPair>& Emitters, bool bControlWorld)
	{
		TMap<FString, float32> Rtpcs;

		for (auto& EmitterPair : Emitters)
		{
			auto Emitter = EmitterPair.Emitter;

			if (IgnoreEmitter(Emitter))
				continue;

			// Previous comparer sorted by control, if worlds were similar to check control/remote, trying it, if it's shit we change it.
			bool bControl = DebugManager.World == Emitter.World;
				
			AActor Owner = nullptr;
			// Try to get unique id for this emitter/instance
			auto OwnerID = TryGetOwnerID(EmitterPair, Owner);
			auto& ActorTracker = TrackingByOwner.FindOrAdd(OwnerID);

			ActorTracker.EmitterOwner = EmitterPair.Owner;
			if (bControl)
			{
				ActorTracker.Local = Emitter;
				ActorTracker.LocalOwner = Owner;
			}
			else 
			{
				ActorTracker.Remote = Emitter;
				ActorTracker.RemoteOwner = Owner;
			}

			for (const auto& EventInstance: Emitter.ActiveEventInstances())
			{
				if (IgnoreEvent(EventInstance))
					continue;

				AddEventInstance(ActorTracker, bControl, Emitter, EventInstance);
			}

			for (const auto& EventIterator: ActorTracker.Events)
			{
				auto& EventData = EventIterator.GetValue();

				if (!EventData.bProcessed)
				{
					if (bControl)
					{
						EventData.LocalStop = Time::PlatformTimeSeconds;
					}
					else
					{
						EventData.RemoteStop = Time::PlatformTimeSeconds;
					}
				}

			}
			
			Rtpcs.Reset();
			if(DebugManager.GetRTPCs(Emitter, Rtpcs))
			{
				for (const auto& RtpcAndValue : Rtpcs)
				{
					AddOrUpdateRtpc(ActorTracker, bControl, Emitter, RtpcAndValue.Key, RtpcAndValue.Value);
				}
			}
		}
	}

	void AddEventInstance(FAudioDebugNetworkActorData& ActorTracker, const bool& bControl, UHazeAudioEmitter Emitter, const FHazeAudioPostEventInstance& EventInstance)
	{
		FAudioDebugNetworkEventData& EventData = ActorTracker.Events.FindOrAdd(EventInstance.EventID);
		if (EventData.bProcessed)
			EventData.Event = EventInstance.Event.Get();

		if (bControl)
		{
			EventData.LocalStart = EventInstance.TimeAtPlay;
		}
		else
		{
			EventData.RemoteStart = EventInstance.TimeAtPlay;
		}

		EventData.bProcessed = true;
	}

	void AddOrUpdateRtpc(FAudioDebugNetworkActorData& ActorTracker, const bool& bControl, UHazeAudioEmitter Emitter, const FString& RtpcName, const float& Value)
	{
		if (IgnoreRtpc(RtpcName))
			return;

		FAudioDebugNetworkRtpcData& RtpcData = ActorTracker.Rtpcs.FindOrAdd(RtpcName);

		RtpcData.bProcessed = true;
		RtpcData.DiscoveredTime = Time::PlatformTimeSeconds;

		if (bControl)
		{
			RtpcData.LocalValue = Value;
		}
		else
		{
			RtpcData.RemoteValue = Value;
		}
	}

	const float SECONDS_UNTIL_DECLARED_MISSING = 1.25;
	const float EVENT_DIFFERENCE_ALLOWED = 1.5;
	const float RTPC_DIFFERENCE_ALLOWED = 0.1;

	TArray<FString> EventTextBuffer;
	TArray<FString> RtpcTextBuffer;

	void Evaluate(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& MiosSection, const FHazeImmediateSectionHandle& Section)
	{
		for (auto& Iterator : TrackingByOwner)
		{
			bool bNothingLeft = true;
			auto& ActorData = Iterator.GetValue();

			EventTextBuffer.Reset();
			RtpcTextBuffer.Reset();

			auto AnyEmitter = ActorData.Local == nullptr ? ActorData.Remote : ActorData.Local;
			if (AnyEmitter == nullptr)
				continue;

			// if (ActorData.Local != nullptr && ActorData.Local.GetAudioComponent() != nullptr)
			// {
			// 	if (ActorData.Local.GetAudioComponent().IsEnabled() == false)
			// 	{
			// 		continue;
			// 	}
			// }

			// if (ActorData.Remote != nullptr && ActorData.Remote.GetAudioComponent() != nullptr)
			// {
			// 	if (ActorData.Remote.GetAudioComponent().IsEnabled() == false)
				// 	{
				// 		continue;
			// 	}
			// }

			if (DebugManager.IsFiltered(Iterator.GetKey().ToString(), false, EDebugAudioFilter::Network))
				continue;

			for (auto& EventIterator: ActorData.Events)
			{
				auto& EventData = EventIterator.GetValue();
				
				if (EventData.IsFinished() && Time::PlatformTimeSeconds > EventData.StopTime() + SECONDS_UNTIL_DECLARED_MISSING)
				{
					if (!Math::IsNearlyEqual(EventData.LocalStart, EventData.RemoteStart, EVENT_DIFFERENCE_ALLOWED))
					{
						ActorData.OutOfSyncEvents.FindOrAdd(EventData.Event, EventData);
					}
					
					EventIterator.RemoveCurrent();
					continue;
				}

				bNothingLeft = false;
				if (Math::IsNearlyEqual(EventData.LocalStart, EventData.RemoteStart, EVENT_DIFFERENCE_ALLOWED) == false)
				{
					auto TimeDiff = EventData.LocalStart - EventData.RemoteStart;

					EventTextBuffer.Add(f"{EventData.Event.Name} - Local '{EventData.LocalStart}', Remote '{EventData.RemoteStart}' DIFF ({TimeDiff}) ");
				}
				EventData.bProcessed = false;
			}  

			for (auto& RtpcIterator: ActorData.Rtpcs)
			{
				auto& RtpcData = RtpcIterator.GetValue();

				if (!RtpcData.bProcessed && Time::PlatformTimeSeconds > RtpcData.DiscoveredTime + SECONDS_UNTIL_DECLARED_MISSING)
				{
					if (Math::IsNearlyEqual(RtpcData.LocalValue, RtpcData.RemoteValue, RTPC_DIFFERENCE_ALLOWED) == false)
						ActorData.OutOfSyncRtpcs.FindOrAdd(RtpcIterator.Key, RtpcData);

					RtpcIterator.RemoveCurrent();
					continue;
				}

				bNothingLeft = false;
				if (Math::IsNearlyEqual(RtpcData.LocalValue, RtpcData.RemoteValue, RTPC_DIFFERENCE_ALLOWED) == false)
				{
					if (AnyEmitter != nullptr)
					{
						RtpcTextBuffer.Add(f"{RtpcIterator.GetKey()} - Local '{RtpcData.LocalValue}', Remote '{RtpcData.RemoteValue}' - {AnyEmitter.GetName()}");
					}
				}

				RtpcData.bProcessed = false;
			}

			if (EventTextBuffer.Num() > 0 || RtpcTextBuffer.Num() > 0)
			{
				auto Actor = ActorData.LocalOwner == nullptr ? ActorData.RemoteOwner : ActorData.LocalOwner;
				if (Actor == nullptr)
					continue;
				
				Section.Text(f"Actor - {Actor.ActorNameOrLabel} - ID - {Iterator.GetKey()}");
				if (EventTextBuffer.Num() > 0)
				{
					auto EventsSection = Section
						.VerticalBox();

					for (const auto& Text : EventTextBuffer)
					{
						EventsSection
							.SlotPadding(20, 0)
							.Text(Text)
							.Color(FLinearColor::Green);
					}
				}

				if (RtpcTextBuffer.Num() > 0)
				{
					auto RtpcsSection = Section
						.VerticalBox();

					for (const auto& Text : RtpcTextBuffer)
					{
						RtpcsSection
							.SlotPadding(20, 0)
							.Text(Text)
							.Color(FLinearColor::Yellow);
					}
				}
			}

			if (bNothingLeft)
				Iterator.RemoveCurrent();
		}
	}

	void DrawInMenu(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& MiosSection, const FHazeImmediateSectionHandle& Section)
	{
		for (auto& Iterator : TrackingByOwner)
		{
			bool bNothingLeft = true;
			auto& ActorData = Iterator.GetValue();

			if (ActorData.OutOfSyncEvents.Num() == 0)
				continue;

			auto Actor = ActorData.LocalOwner == nullptr ? ActorData.RemoteOwner : ActorData.LocalOwner;
			if (Actor == nullptr)
				continue;

			MiosSection.Text(f"Actor - {Actor.ActorNameOrLabel} - ID - {Iterator.GetKey()}");

			auto EventsSection = MiosSection
				.VerticalBox();

			for (const auto& EventAndData : ActorData.OutOfSyncEvents)
			{
				auto& EventData = EventAndData.Value;

				EventsSection.SlotPadding(20,0,)
				.Text(f"Out of sync event -> {EventData.Event.Name}");
				
				if (EventsSection.Button(f"Find {EventData.Event.Name}")
					.Padding(20,0))
				{
					Editor::OpenEditorForAsset(EventData.Event.GetPathName());
				}

				auto SoundDefOwner = Cast<UHazeSoundDefBase>(ActorData.EmitterOwner);
				if (SoundDefOwner != nullptr)
				{
					if (EventsSection.Button(f"Find {SoundDefOwner.Name}")
						.Padding(20,0))	
					{
						auto AssetPath = SoundDefOwner.Class.GetPathName();
						// So it doesn't open the blueprintclass instead of SD.
						AssetPath.RemoveFromEnd("_C");
						Editor::OpenEditorForAsset(AssetPath);
					}
				}
			}

							// if (ActorData.OutOfSyncRtpcs.Num() > 0)
				// {
				// 	auto RtpcsSection = Section
				// 		.VerticalBox();

				// 	for (const auto& RtpcData : ActorData.OutOfSyncRtpcs)
				// 	{
				// 		EventsSection.Text(f"Out of sync event -> {RtpcData.}")
				// 	}
				// }
		}
	}

	#endif
}