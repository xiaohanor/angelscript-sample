class UAudioDebugSpots : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Spots; }
	
	FString GetTitle() override
	{
		return "Spots";
	}

	bool InViewOrRange(const TArray<AHazePlayerCharacter>& Players, USpotSoundComponent SpotComponent)
	{
		float Radius = 500;
		if (SpotComponent.Emitter != nullptr)
		{
			if (AudioDebug::FilterAudioComponent(Players, SpotComponent.Emitter.GetAudioComponent()))
				return false;
		}

		for (auto Player: Players)
		{
			if (!SceneView::ViewFrustumPointRadiusIntersection(Player, SpotComponent.WorldLocation, Radius, 100000))
				continue;
			
			return true;
		}

		return false;
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		auto Players = Game::GetPlayers();

		for(auto SpotSound : DebugManager.SpotSounds)
		{
			if (SpotSound == nullptr)
				continue;

			if (InViewOrRange(Players, SpotSound) == false)
				continue;

			DebugSpot(DebugManager, SpotSound);
		}
	}

	private void DebugSpot(UAudioDebugManager DebugManager, const USpotSoundComponent SpotSound)
	{
		FString ActorName = AudioDebug::GetActorLabel(SpotSound.GetOwner()) + "." + SpotSound.GetName().ToString();
		if (DebugManager.IsFiltered(ActorName, true, EDebugAudioFilter::Spots))
			return;

		// Right now only debugging for Basic-mode, will need to cater for the different modes
		Debug::DrawDebugSolidSphere(SpotSound.GetWorldLocation(), 50, SpotSound.WidgetColor);

		auto MultiSpot = Cast<USpotSoundMultiComponent>(SpotSound.ModeComponent);
		if (SpotSound.Emitter != nullptr)
			AudioDebug::VisualizeAudioComponent(DebugManager, SpotSound.Emitter.GetAudioComponent());
		else if (MultiSpot != nullptr)
		{
			for (auto& MultiEmitter : MultiSpot.MultiEmitters)
			{
				if (MultiEmitter.AudioComponent == nullptr)
					continue;

				AudioDebug::VisualizeAudioComponent(DebugManager, MultiEmitter.AudioComponent);
			}
		}

		FVector DrawNameLocation = SpotSound.GetWorldLocation();
		DrawNameLocation.Z += 100;
		
		if (SpotSound.LinkedZone != nullptr)
		{
			ActorName += "\n  LinkedZone - " + AudioDebug::GetActorLabel(SpotSound.Owner);
		}

		Debug::DrawDebugString(DrawNameLocation, ActorName, SpotSound.WidgetColor, Scale = 1.25);
	}
}