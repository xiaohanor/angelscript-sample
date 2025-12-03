class UAudioDebugEffects : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Effects; }
	
	FString GetTitle() override
	{
		return "Effects";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		Super::Draw(DebugManager, Section);

		auto AudioEffectSystem = Game::GetSingleton(UHazeAudioRuntimeEffectSystem);
		if (AudioEffectSystem == nullptr)
		{
			return;
		}

		Section.Text("All Effects;");
		auto ActiveEffectsBox = Section.VerticalBox()
			.SlotPadding(20, 0);

		for (const auto& EffectInstance : AudioEffectSystem.GetEffectInstances())
		{
			FString ShareSetName = EffectInstance.ShareSet != nullptr ? EffectInstance.ShareSet.Name.ToString() : "ShareSet Unloaded";
			
			ActiveEffectsBox
				.SlotPadding(20, 0)
				.Text(f"Target: {ShareSetName}")
				.Color(FLinearColor::Green);

			ActiveEffectsBox
				.SlotPadding(20, 0)
				.Text(f"Instigator: {EffectInstance.Instigator}")
				.Color(FLinearColor::Green);

			ActiveEffectsBox
				.SlotPadding(20, 0)
				.Text(f"Alpha: {EffectInstance.Alpha}")
				.Color(FLinearColor::Blue);
		}
	}
}