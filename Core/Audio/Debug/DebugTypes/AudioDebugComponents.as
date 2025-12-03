namespace AudioDebug
{
	enum EAudioComponentDebugState
	{
		// Single positions
		Disabled,
		NotPlaying,
		Virtualized,
		Playing,
		Proxy,
		// // Multi
		Multi_Disabled,
		Multi_NotPlaying,
		Multi_Virtualized,
		Multi_Playing,
	}

	struct FAudioComponentColor
	{
		TArray<FLinearColor> ColorsByState;

		FAudioComponentColor()
		{
			// Disabled
			ColorsByState.Add(FLinearColor::Gray);
			// Not Playing
			ColorsByState.Add(FLinearColor::Red);
			// Virtualized
			ColorsByState.Add(FLinearColor::LucBlue);
			// Playing
			ColorsByState.Add(FLinearColor::Green);
			// Proxy
			ColorsByState.Add(FLinearColor::DPink);

			// Multi
			// Disabled
			ColorsByState.Add(FLinearColor(0.22, 0.35, 0.40));
			// Not Playing
			ColorsByState.Add(FLinearColor(1.00, 0.37, 0.00));
			// Virtualized
			ColorsByState.Add(FLinearColor::LucBlue);
			// Playing
			ColorsByState.Add(FLinearColor(0.79, 0.85, 0.00));
		}

		FLinearColor GetColor(EAudioComponentDebugState State, bool Multi) const
		{
			return ColorsByState[int(State) + (Multi ? 5 : 0)];
		}
	}

	const FAudioComponentColor ComponentColor;

	EAudioComponentDebugState GetComponentState(const UHazeAudioComponent AudioComponent, const UHazeAudioEmitter Emitter = nullptr)
	{
		if (Emitter != nullptr)
		{
			if(Emitter.HasProxy())
			{
				return EAudioComponentDebugState::Proxy;
			}

			if (Emitter.IsVirtualized())
			{
				if (!Emitter.IsPlaying())
				{
					return EAudioComponentDebugState::NotPlaying;
				}

				return EAudioComponentDebugState::Virtualized;
			}

			if (Emitter.IsPlaying())
			{
				return EAudioComponentDebugState::Playing;
			}

			return EAudioComponentDebugState::NotPlaying;
		}

		if (AudioComponent == nullptr)
		{
			return EAudioComponentDebugState::Playing;
			//return Emitter.IsPlaying() ? EAudioComponentDebugState::Playing : EAudioComponentDebugState::NotPlaying;
		}

		if (AudioComponent.IsPlaying())
		{
			return EAudioComponentDebugState::Playing;
		}

		if (!AudioComponent.IsEnabled())
		{
			return EAudioComponentDebugState::Disabled;
		}

		return EAudioComponentDebugState::NotPlaying;
	}

	bool VisualizeAudioComponent(UAudioDebugManager DebugManager, UHazeAudioComponent AudioComponent)
	{
		if (AudioComponent == nullptr)
			return false;

		TArray<FString> AggregatedEmitterList;

		auto StateOfAudioComponent = GetComponentState(AudioComponent);
		if ((StateOfAudioComponent == EAudioComponentDebugState::NotPlaying || StateOfAudioComponent == EAudioComponentDebugState::Disabled)
				&& !DebugManager.MiscFlags.bShowInactiveAudioComponents)
			return false;	

		auto ClosestListener = AudioComponent.GetClosestPlayer();
		auto ClosestDistance = AudioComponent.GetClosestListenerDistance();

		const auto& MultiPositions = AudioComponent.GetMultipleSoundPositions();
		auto Color = AudioDebug::ComponentColor.GetColor(StateOfAudioComponent, MultiPositions.Num() > 0);

		FVector WorldLocation = AudioComponent.GetWorldLocation();
		if (MultiPositions.Num() > 0)
		{
			if (MultiPositions.Num() == 2 && ClosestListener != nullptr)
			{
				WorldLocation = MultiPositions[ClosestListener.IsMio() ? 0 : 1].Position;
			}
			else
				WorldLocation = MultiPositions[0].Position;
		}

		for (int i=0; i < AudioComponent.EmitterPairs.Num(); ++i)
		{
			auto Emitter = AudioComponent.EmitterPairs[i].Emitter;
			if(Emitter.HasProxy())
				continue;

			FString BaseName = Emitter.Name.ToString();
			// If it's a fireforget sound get the name from the event instead.
			if (AudioComponent.IsAFireForgetObject())
			{
				const auto Events = Emitter.ActiveEventInstances();
				if (Events.Num() != 0)
				{
					const auto& FirstEvent = Events[0];
					BaseName = FirstEvent.EventName();
				}
			}

			if (DebugManager.IsFiltered(BaseName, true, EDebugAudioFilter::AudioComponents))
				continue;

			auto EmitterState = GetComponentState(AudioComponent, Emitter);
			if ((EmitterState == EAudioComponentDebugState::NotPlaying || EmitterState == EAudioComponentDebugState::Disabled)
				&& !DebugManager.MiscFlags.bShowInactiveAudioComponents)
				continue;

			AggregatedEmitterList.Add(BaseName);
		}

		TArray<FString> AggregatedProxyEmitterList;
		FName ProxyListenerName = NAME_None;
		float ProxyListenerDistance = MAX_flt;
		bool bFoundProxy = false;
		
		for (int i=0; i < AudioComponent.EmitterPairs.Num(); ++i)
		{
			auto Emitter = AudioComponent.EmitterPairs[i].Emitter;
			if(!Emitter.HasProxy())
				continue;

			FString BaseName = Emitter.Name.ToString();
			if (DebugManager.IsFiltered(BaseName, true, EDebugAudioFilter::AudioComponents))
				continue;

			AggregatedProxyEmitterList.AddUnique(BaseName);
		
			if(!bFoundProxy)
			{
				auto Listener = Emitter.GetProxyListener();
				ProxyListenerName = Listener.GetName();
				ProxyListenerDistance = Listener.GetWorldLocation().Distance(AudioComponent.GetWorldLocation());	
			}

			bFoundProxy = true;
		}

		// Proxy Emitters
		if(AggregatedProxyEmitterList.Num() > 0)
		{			
			FLinearColor ProxyColor = AudioDebug::ComponentColor.GetColor(EAudioComponentDebugState::Proxy, false);

			FString AggregatedResult = f"Listener: {ProxyListenerName} - Distance: {int(ProxyListenerDistance)} \n";
			for (int i=0; i < AggregatedProxyEmitterList.Num(); ++i)
			{
				AggregatedResult += f"   {AggregatedProxyEmitterList[i]}\n";

				Debug::DrawDebugPoint(WorldLocation, 30.0, PointColor = ProxyColor);
					
				if (AudioComponent.GetAttachParent() != nullptr)
					AggregatedResult += "\n  Attachment - " + AudioComponent.GetAttachParent().Owner.Name + ", Attach: " + AudioComponent.GetAttachParent().Name+ " Bone: " + AudioComponent.GetAttachSocketName();

				Debug::DrawDebugString(WorldLocation, AggregatedResult, ProxyColor, bOutline = true);				
			}	
		}

		if (AggregatedEmitterList.Num() == 0)
			return false;	

		FString ListenerName = ClosestListener == nullptr ? "None" : ClosestListener.GetName().ToString();

		FString AggregatedResult = f"Listener: {ListenerName} - Distance: {int(ClosestDistance)} \n";
		for (int i=0; i < AggregatedEmitterList.Num(); ++i)
		{
			AggregatedResult += f"   {AggregatedEmitterList[i]}\n";
		}		

		if (MultiPositions.Num() > 0)
		{
			for (const auto& SoundPosition: MultiPositions)
			{
				Debug::DrawDebugPoint(SoundPosition.Position, 30.0, PointColor = Color);
				Debug::DrawDebugString(SoundPosition.Position, AggregatedResult, Color);
			}
		}
		else
		{
			Debug::DrawDebugPoint(WorldLocation, 30.0, PointColor = Color);

			// Add zones names
			if (DebugManager.MiscFlags.bShowAuxSends)
			{
				auto ReverbComponent = AudioComponent.GetReverbComponent();
				if (ReverbComponent != nullptr)
				{
					AggregatedResult += "ZoneOverlaps; \n";
					for (auto Overlap : ReverbComponent.ZoneOverlaps)
					{
						AggregatedResult += f"   {AudioDebug::GetActorLabel(Overlap.Zone)} - {Overlap.AttenuationDistance} \n";
					}
				}
			}

			if (AudioComponent.GetAttachParent() != nullptr)
				AggregatedResult += "\n  Attachment - " + AudioComponent.GetAttachParent().Owner.Name + ", Attach: " + AudioComponent.GetAttachParent().Name+ " Bone: " + AudioComponent.GetAttachSocketName();

			Debug::DrawDebugString(WorldLocation, AggregatedResult, Color, bOutline = true);

			Debug::DrawDebugDirectionArrow(WorldLocation, AudioComponent.ForwardVector, 1000.0, 15.0, Color, 1.5);
		}

		if (DebugManager.MiscFlags.bShowAttenuationScaling && AudioComponent.GetAttenuationRadius() > 0)
		{
			auto SphereColor = FLinearColor::Purple;
			SphereColor.A = 0.15;

			Debug::DrawDebugSolidSphere(WorldLocation, AudioComponent.GetAttenuationRadius(), SphereColor, 0, 6);
		}

		return true;
	}

	bool DrawAudioComponent(
		UAudioDebugManager DebugManager,
		FHazeImmediateVerticalBoxHandle& Active,
		FHazeImmediateVerticalBoxHandle& Inactive,
		UHazeAudioEmitter Emitter)
	{
		auto StateOfAudioComponent = GetComponentState(Emitter.GetAudioComponent(), Emitter);

		if (!DebugManager.MiscFlags.bShowInactiveAudioComponents && StateOfAudioComponent == EAudioComponentDebugState::NotPlaying)
			return false;

		if (StateOfAudioComponent == EAudioComponentDebugState::Playing)
			return DrawAudioComponent(DebugManager, Active, Emitter);
		else
			return DrawAudioComponent(DebugManager, Inactive, Emitter);
	}

	FString GetOwnerName(UHazeAudioComponent AudioComponent)
	{
		if (AudioComponent == nullptr || AudioComponent.Owner == nullptr)
			return "Global";

		auto AttachParent = AudioComponent.GetAttachParent();
		if (AttachParent != nullptr)
			return AttachParent.Owner.Name.ToString();

		return AudioComponent.Owner.Name.ToString();
	}

	bool DrawAudioComponent(
		UAudioDebugManager DebugManager,
		FHazeImmediateVerticalBoxHandle& Section,
		UHazeAudioEmitter Emitter)
	{
		UHazeAudioComponent AudioComponent = Emitter.GetAudioComponent();
		FString OwnerName = GetOwnerName(AudioComponent);

		auto StateOfAudioComponent = GetComponentState(AudioComponent, Emitter);

		FString BaseName = Emitter.Name.ToString();
		// If it's a fireforget sound get the name from the event instead.
		if (AudioComponent != nullptr && AudioComponent.IsAFireForgetObject())
		{
			const auto Events = AudioComponent.GetAnyEmitter().ActiveEventInstances();
			if (Events.Num() > 0)
			{
				const auto& FirstEvent = Events[0];
				BaseName = FirstEvent.EventName();
			}
		}
		FString AudioComponentName = f"{OwnerName} - {BaseName}";

		if (DebugManager.IsFiltered(AudioComponentName, false, EDebugAudioFilter::AudioComponents))
			return false;

		bool bMulti = false;
		FString ExtraData = "";
		if (AudioComponent != nullptr)
		{
			auto ClosestListener = AudioComponent.GetClosestPlayer();
			auto ClosestDistance = AudioComponent.GetClosestListenerDistance();
			FString ListenerName = ClosestListener == nullptr ? "None" : ClosestListener.GetName().ToString();
			ExtraData = f"\n Listener: {ListenerName} \n Distance: {int(ClosestDistance)}";
			if (Emitter.IsVirtualized())
				ExtraData += f"- VIRTUALIZED";

			bMulti = AudioComponent.GetMultipleSoundPositions().Num() > 0;
		}
		auto Color = AudioDebug::ComponentColor.GetColor(StateOfAudioComponent, bMulti);

		// Widget
		auto AssetBox = Section.HorizontalBox();
		AssetBox.SlotPadding(5,0,0,0);
		AssetBox.Text(AudioComponentName + ExtraData)
				.Color(Color);

		for	(const auto Instance: Emitter.ActiveEventInstances())
			DrawPostEvent(DebugManager, Section, Instance);

		if (DebugManager.MiscFlags.bShowAttenuationScaling)
		{
			auto ExtraInfo = Section.HorizontalBox();
			ExtraInfo.SlotPadding(25,0,0,0);
			ExtraInfo
				.Text(f"Attuenuation: {Emitter.GetScaledAttenuationRadius()} (SCALED) by: {Emitter.GetAttenuationScaling()} ")
				.Color(FLinearColor::Purple);
		}

		auto ReverbComponent = AudioComponent != nullptr ? AudioComponent.GetReverbComponent() : nullptr;
		if (DebugManager.MiscFlags.bShowOverlappingEnvironments && ReverbComponent != nullptr)
		{
			for (const auto ValueAndEnviroment: ReverbComponent.OverlappedEnvironmentsRelevances)
			{
				Section
					.SlotPadding(25,0,0,0)
					.Text(("" + ValueAndEnviroment.Key + ": " + ValueAndEnviroment.Value))
					.Color(FLinearColor::Teal);
			}
		}

		if (DebugManager.MiscFlags.bShowAuxSends)
		{
			if (ReverbComponent != nullptr)
			{
				auto VLBox = Section.VerticalBox();

				for (const auto& AuxSendValue : ReverbComponent.GetAuxSendValues())
				{
					// const auto AuxSendValue = AuxSend;
					VLBox
						.SlotPadding(25,0,0,0)
						.Text(f"AuxSend({AuxSendValue.AuxBus.ShortID}), Send: {AuxSendValue.Send}, {AuxSendValue.AuxBus:<2}")
						.Color(AuxSendValue.bIsVirtual ? FLinearColor::Red : FLinearColor::Blue);
				}
			}
		}

		if (DebugManager.MiscFlags.bShowRTPCs)
		{
			TMap<FString, float32> Rtpcs;
			if(DebugManager.GetRTPCs(Emitter, Rtpcs))
			{
				auto VLBox = Section.VerticalBox();

				for	(const auto& KeyValuePair: Rtpcs)
				{
					if (DebugManager.IsFiltered(KeyValuePair.Key, false, EDebugAudioFilter::RTPCs))
						continue;

					VLBox
						.SlotPadding(25,0,0,0)
						.Text(f"{KeyValuePair.Key} : {KeyValuePair.Value:<2}")
						.Color(FLinearColor::Yellow);
				}
			}
		}

		if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::NodeProperties))
		{
			TArray<FHazeAudioNodePropertySet> NodeProperties;
			if(DebugManager.GetNodeProperties(Emitter, NodeProperties))
			{
				auto VLBox = Section.VerticalBox();

				for	(const auto& PropertySet: NodeProperties)
				{
					if (!PropertySet.AudioNode.IsValid())
						continue;

					FString NameOfTheNode = PropertySet.AudioNode.Get().Name.ToString();

					if (DebugManager.IsFiltered(NameOfTheNode, false, EDebugAudioFilter::NodeProperties))
						continue;

					VLBox
						.SlotPadding(25,0,0,0)
						.Text(NameOfTheNode)
						.Color(FLinearColor::Purple);

					for (const auto& PropertyTypeAndValue : PropertySet.Properties)
					{

						VLBox
							.SlotPadding(50,0,0,0)
							.Text(f"{PropertyTypeAndValue.Key :n } : {PropertyTypeAndValue.Value:<2}")
							.Color(FLinearColor::Yellow);

					}
				}
			}
		}

		return true;
	}

	void DrawPostEvent(UAudioDebugManager DebugManager, FHazeImmediateVerticalBoxHandle& Section, const FHazeAudioPostEventInstance& Instance)
	{
		if (DebugManager.IsFiltered(Instance.EventName(), false, EDebugAudioFilter::Events))
			return;

		{
			FString EventType = "";
			if ((Instance.EventType & EHazeAudioEventInstanceType::Play) != 0)
			{
				EventType += "Play";
			}
			if ((Instance.EventType & EHazeAudioEventInstanceType::Stop) != 0)
			{
				EventType += "Stop";
			}

			if ((Instance.EventType & EHazeAudioEventInstanceType::Loop) != 0)
			{
				EventType += "- Loop";
			}
			else
			{
				EventType += "- OneShot";
			}

			auto VLBox = Section.HorizontalBox();
			VLBox
				.SlotPadding(25,0,0,0)
				.Text(f"{Instance.EventName()} : PlayingID({Instance.PlayingID:<2}) : {EventType}")
				.Color(Instance.bIsVirtualized ? FLinearColor::Red : FLinearColor::White);
		}

		if (DebugManager.MiscFlags.bShowRTPCs)
		{
			TMap<FString, float32> Rtpcs;
			if(DebugManager.GetEventRTPCs(Instance, Rtpcs))
			{
				auto VLBox = Section.VerticalBox();

				for	(const auto& KeyValuePair: Rtpcs)
				{
					if (DebugManager.IsFiltered(KeyValuePair.Key, false, EDebugAudioFilter::RTPCs))
						continue;

					VLBox
						.SlotPadding(50,0,0,0)
						.Text(f"{KeyValuePair.Key} : {KeyValuePair.Value:<2}")
						.Color(FLinearColor::Yellow);
				}
			}
		}

		if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::NodeProperties))
		{
			TArray<FHazeAudioNodePropertySet> NodeProperties;
			if(DebugManager.GetEventNodeProperties(Instance, NodeProperties))
			{
				auto VLBox = Section.VerticalBox();

				for	(const auto& PropertySet: NodeProperties)
				{
					if (!PropertySet.AudioNode.IsValid())
						continue;

					FString NameOfTheNode = PropertySet.AudioNode.Get().Name.ToString();

					if (DebugManager.IsFiltered(NameOfTheNode, false, EDebugAudioFilter::NodeProperties))
						continue;

					VLBox
						.SlotPadding(25,0,0,0)
						.Text(NameOfTheNode)
						.Color(FLinearColor::Purple);

					for (const auto& PropertyTypeAndValue : PropertySet.Properties)
					{
						VLBox
							.SlotPadding(50,0,0,0)
							.Text(f"{PropertyTypeAndValue.Key :n} : {PropertyTypeAndValue.Value:<2}")
							.Color(FLinearColor::Yellow);
					}
				}
			}
		}
	}

	const float MaxRenderDistance = Math::Pow(25000, 2);

	bool PositionInViewOrRange(const TArray<AHazePlayerCharacter>& Players, const FVector& Location, const float& AttenuationRange = 0)
	{
		auto MaxRange = Math::Max(MaxRenderDistance, Math::Pow(AttenuationRange, 2));

		for (auto Player: Players)
		{
			if (Player.ViewLocation.DistSquared(Location) > MaxRange)
				continue;

			if (!SceneView::IsInView(Player, Location))
				continue;

			return true;
		}

		return false;
	}

	bool FilterAudioComponent(const TArray<AHazePlayerCharacter>& Players, const UHazeAudioComponent Component)
	{
		if (Component == nullptr)
			return true;

		if (!Component.IsUsingMultiplePositions())
		{
			if (PositionInViewOrRange(Players, Component.WorldLocation, Component.GetAttenuationRadius()))
				return false;
		}
		else
		{
			const auto& MultiPositions = Component.GetMultipleSoundPositions();
			for (const auto& SoundPosition:  MultiPositions)
			{
				if (PositionInViewOrRange(Players, SoundPosition.Position, Component.GetAttenuationRadius()))
					return false;
			}
		}

		return true;
	}

}

class UAudioDebugComponents : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::AudioComponents; }

	FString GetTitle() override
	{
		return "AudioComponents";
	}

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager,
			  const FHazeImmediateScrollBoxHandle& Section) override
	{
		Super::Menu(DevMenu, DebugManager, Section);

		auto MenuDebugConfig = DevMenu.MenuDebugConfig;

		bool RtpcCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowRTPCs)
			.Label("Show RTPCs")
			.Tooltip("If to show rtpcs or not");

		if (MenuDebugConfig.MiscFlags.bShowRTPCs != RtpcCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowRTPCs = RtpcCheckBoxEnabled;
			MenuDebugConfig.Save();
		}

		bool AuxsSendCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowAuxSends)
			.Label("Show AuxSends")
			.Tooltip("If to show aux sends or not");

		if (MenuDebugConfig.MiscFlags.bShowAuxSends != AuxsSendCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowAuxSends = AuxsSendCheckBoxEnabled;
			MenuDebugConfig.Save();
		}

		bool EnvironmentsCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowOverlappingEnvironments)
			.Label("Show OverlappingEnvironments")
			.Tooltip("If to show overlapping environments or not");

		if (MenuDebugConfig.MiscFlags.bShowOverlappingEnvironments != EnvironmentsCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowOverlappingEnvironments = EnvironmentsCheckBoxEnabled;
			MenuDebugConfig.Save();
		}

		bool AttenuationCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowAttenuationScaling)
			.Label("Show Attenuation")
			.Tooltip("If to show attenuation scaling or not");

		if (MenuDebugConfig.MiscFlags.bShowAttenuationScaling != AttenuationCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowAttenuationScaling = AttenuationCheckBoxEnabled;
			MenuDebugConfig.Save();
		}

		bool InactiveCompsCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowInactiveAudioComponents)
			.Label("Show Inactive Components")
			.Tooltip("If to show audio components that are not playing any sounds");

		if (MenuDebugConfig.MiscFlags.bShowInactiveAudioComponents != InactiveCompsCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowInactiveAudioComponents = InactiveCompsCheckBoxEnabled;
			MenuDebugConfig.Save();
		}
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		Super::Draw(DebugManager, Section);

		auto ActiveComps = Section.VerticalBox();
		auto InactiveComps = Section.VerticalBox();

		int32 MaxCount = 30;

		for	(auto Emitter : DebugManager.GetRegisteredEmitters())
		{
			if (AudioDebug::DrawAudioComponent(DebugManager, ActiveComps, InactiveComps, Emitter))
				++DrawCount;

			if (DrawCount > MaxCount)
				break;
		}
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		Super::Visualize(DebugManager);

		// A minor optimization to filter out shit we don't need to render.
		auto Players = Game::GetPlayers();

		for	(auto Component : DebugManager.GetRegisteredComponents())
		{
			if (AudioDebug::FilterAudioComponent(Players, Component))
				continue;

			AudioDebug::VisualizeAudioComponent(DebugManager, Component);
		}

		for	(auto Component : DebugManager.GetWaterReverbComponents())
		{
			if (Component == nullptr)
				continue;

			Debug::DrawDebugPoint(Component.WorldLocation, 20, FLinearColor::Blue, bDrawInForeground = true);
		}
	}
}