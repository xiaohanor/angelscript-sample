class UAudioDebugPlayers : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Players; }
	
	FString GetTitle() override
	{
		return "Players";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::AudioComponents))
			return;

		auto Active = Section.VerticalBox();
		auto Inactive = Section.VerticalBox();

		for (auto Player : Game::Players)
		{
			auto Emitter =  Player.PlayerAudioComponent.GetAnyEmitter();
			if (Emitter == nullptr)
				continue;
			
			if (Emitter.IsPlaying() || Emitter.GetAudioComponent() == nullptr)
				AudioDebug::DrawAudioComponent(DebugManager, Active, Emitter);
			else
				AudioDebug::DrawAudioComponent(DebugManager, Inactive, Emitter);

		}
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		const auto Players = Game::Players;
		for (auto Player : Players)
			AudioDebug::VisualizeAudioComponent(DebugManager, Player.PlayerAudioComponent);


		if (Players.Num() == 0)
		{
			for (auto Listener : DebugManager.RegisteredListeners)
			{
				auto ListenerLocation = Listener.WorldLocation;

				Debug::DrawDebugArrow(ListenerLocation, ListenerLocation + (Listener.ForwardVector * 500), 40, FLinearColor::Blue, 10);
				Debug::DrawDebugPoint(ListenerLocation, 20.0, FLinearColor::Purple, bDrawInForeground = true);
			}
		}
	}
}