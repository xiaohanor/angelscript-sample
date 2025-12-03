class UAudioDebugZones: UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Zones; }

	FString GetTitle() override
	{
		return "Zones";
	}

	// We know Draw is called first, so cache zones there.
	uint32 LastFrame = 0;
	TArray<AActor> ZoneActors;

	void GetZones(UAudioDebugManager DebugManager)
	{
		if (LastFrame == Time::FrameNumber)
			return;

		LastFrame = Time::FrameNumber;
		DebugManager.GetZones(ZoneActors);
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		GetZones(DebugManager);

		auto InactiveZones = Section.VerticalBox();
		auto ActiveZones = Section.VerticalBox();

		for	(auto Actor : ZoneActors)
		{
			auto Zone = Cast<AHazeAudioZone>(Actor);

			if (!DebugManager.IsFiltered(AudioDebug::GetActorLabel(Zone), false, EDebugAudioFilter::Zones))
				DrawAudioZone(DebugManager, InactiveZones, ActiveZones, Zone);
		}
	}

	private UDataAsset GetZoneAsset(AHazeAudioZone Zone)
	{
		auto AmbientZone = Cast<AAmbientZone>(Zone);
		if (AmbientZone != nullptr)
			return AmbientZone.ZoneAsset;

		auto ReverbZone = Cast<AReverbZone>(Zone);
		if (ReverbZone != nullptr)
			return ReverbZone.ZoneAsset;

		return nullptr;
	}

	void DrawAudioZone(
		UAudioDebugManager DebugManager,
		FHazeImmediateVerticalBoxHandle& Active,
		FHazeImmediateVerticalBoxHandle& Inactive,
		AHazeAudioZone Zone)
	{
		bool bActive = ((Zone.IsZoneEnabled() && Zone.IsActorTickEnabled()) || Zone.ZoneRTPCValue > 0);

		if (bActive)
		{
			DrawZoneInVerticalGroup(DebugManager, Active, true, Zone);
		}
		else
		{
			DrawZoneInVerticalGroup(DebugManager, Inactive, false, Zone);
		}
	}

	private void DrawZoneInVerticalGroup(
		UAudioDebugManager DebugManager,
		const FHazeImmediateVerticalBoxHandle& BoxHandle,
		const bool bActive,
		AHazeAudioZone Zone)
	{
		auto ZoneAsset = GetZoneAsset(Zone);
		auto ZoneAssetName = ZoneAsset != nullptr ? ZoneAsset.Name.ToString() : "";
		auto ReverbName = Zone.ReverbBus != nullptr ? Zone.ReverbBus.Name.ToString() : "";

		auto Color = bActive ?
			AudioZone::ZoneColors.GetActiveColor(Zone) :
			AudioZone::ZoneColors.GetZoneColor(Zone);

		if (bActive && Zone.ZoneRTPCValue == 0)
		{
			Color = FLinearColor::Yellow;
		}

		if (Zone.ZoneType == EHazeAudioZoneType::Portal)
		{
			BoxHandle
				.Text(f"{AudioDebug::GetActorLabel(Zone)}")
				.Color(Color);

			auto PortalZone = Cast<APortalZone>(Zone);

			for (auto PortalsZone: PortalZone.Connections.Zones)
			{
				if (PortalsZone!= nullptr)
				{
					BoxHandle
						.SlotPadding(25,0,0,0)
						.Text(f"ZoneA: {AudioDebug::GetActorLabel(PortalsZone)}");
				}
			}
			return;
		}

		BoxHandle.Text(f"{AudioDebug::GetActorLabel(Zone)}, Environment: {Zone.EnvironmentType}")
			.Color(Color);

		if (Zone.EnsureReverbReady())
		{
			BoxHandle.SlotPadding(25,0,0,0);
			BoxHandle.Text(f"ZoneAsset: {ZoneAssetName}, Reverb: {ReverbName}")
				.Color(Color);
			// BoxHandle.Text(f"ReverbBus: 		" + ReverbName)
			// 	.Color(Color);
			BoxHandle.SlotPadding(25,0,0,0);
			BoxHandle.Text(f"RTPC: {Zone.ZoneRTPCValue}")
				.Color(Color);

			BoxHandle.SlotPadding(25,0,0,0);
			BoxHandle.Text(f"Relevance: {Zone.GetZoneRelevance()}")
				.Color(Color);

			// BoxHandle.SlotPadding(25,0,0,0);
			// BoxHandle.Text(f"Steal Reverb: {Zone.IsStealingReverb()}")
			// 	.Color(Color);


			auto AmbientZone = Cast<AAmbientZone>(Zone);
			// RANDOM SPOTS
			if (AmbientZone != nullptr)
			{
				BoxHandle.SlotPadding(25,0,0,0);
				BoxHandle.Text(f"Panning: {AmbientZone.GetPanningValue()}")
					.Color(Color);

				if (AmbientZone.ActiveSpots.Num() > 0)
				{
					BoxHandle.SlotPadding(25,0,0,0);
					BoxHandle
						.Text("Random Spots")
						.Color(Color);

					for(int i=0; i < AmbientZone.ActiveSpots.Num(); ++i)
					{
						auto& ActiveSpot = AmbientZone.ActiveSpots[i];
						auto& RandomSpot = AmbientZone.RandomSpots.SpotSounds[i];

						if (RandomSpot.Event == nullptr)
							continue;

						FLinearColor RandomColor = ActiveSpot.EventInstance.PlayingID == 0 ?
							FLinearColor::Gray : FLinearColor::Green;

						BoxHandle.SlotPadding(35,0,0,0);
						BoxHandle.Text(RandomSpot.Event.ToString())
							.Color(RandomColor);

						BoxHandle.SlotPadding(50,0,0,0);
						BoxHandle.Text("Countdown: " + (ActiveSpot.NextTime - ActiveSpot.CurrentTime))
							.Color(RandomColor);

						BoxHandle.SlotPadding(50,0,0,0);
						BoxHandle.Text("HorizontalOffset: " + ActiveSpot.HorizontalOffset + " / VerticalOffset: " + ActiveSpot.VerticalOffset )
							.Color(RandomColor);
					}
				}
			}
			//

		}else {
			BoxHandle.SlotPadding(25,0,0,0);
			BoxHandle.Text(f"RTPC: {Zone.ZoneRTPCValue}")
				.Color(Color);
		}

		BoxHandle.SlotPadding(25,0,0,0);
		BoxHandle.Text(f"Priority: {Zone.Priority}")
			.Color(Color);
	}

	float MaxRenderDistance = 100000;

	bool InViewOrRange(const TArray<AHazePlayerCharacter>& Players, AHazeAudioZone Zone)
	{
		FBoxSphereBounds Bounds = Zone.BrushComponent.Bounds;

		for (auto Player: Players)
		{
			if (!SceneView::ViewFrustumPointRadiusIntersection(Player, Bounds.Origin, Bounds.SphereRadius, 100000))
				continue;

			return true;
		}

		return false;
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		GetZones(DebugManager);

		auto Players = Game::GetPlayers();

		for	(auto Actor : ZoneActors)
		{
			auto Zone = Cast<AHazeAudioZone>(Actor);

			if (InViewOrRange(Players, Zone) == false)
				continue;

			if (!DebugManager.IsFiltered(AudioDebug::GetActorLabel(Zone), true, EDebugAudioFilter::Zones))
				DebugZone(Zone);
		}
	}

	private void DebugZone(AHazeAudioZone Zone)
	{
		AudioZone::DrawZone(Zone);

		if (Zone.RandomSpots == nullptr)
			return;

		auto AmbientZone = Cast<AAmbientZone>(Zone);
		if (AmbientZone == nullptr)
			return;

		for (auto RandomSpot: AmbientZone.ActiveSpots)
		{
			Debug::DrawDebugPoint(RandomSpot.PlayingLocation, 20.0, FLinearColor::Green);
			Debug::DrawDebugString(RandomSpot.PlayingLocation, RandomSpot.EventInstance.EventName(), FLinearColor::Green);
		}
	}

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager,
			  const FHazeImmediateScrollBoxHandle& Section) override
	{
		Super::Menu(DevMenu, DebugManager, Section);

		auto MenuDebugConfig = DevMenu.MenuDebugConfig;

		bool RtpcCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowZonesAttenuation)
			.Label("Show Zones Attenuation")
			.Tooltip("If to show zones attenuation or not");

		// Update if changed
		if (RtpcCheckBoxEnabled != MenuDebugConfig.MiscFlags.bShowZonesAttenuation)
		{
			Console::SetConsoleVariableInt("HazeAudio.ShowZonesAttenuation", RtpcCheckBoxEnabled ? 1 : 0, "", true);
			MenuDebugConfig.MiscFlags.bShowZonesAttenuation = RtpcCheckBoxEnabled;
			MenuDebugConfig.Save();
		}
	}
}