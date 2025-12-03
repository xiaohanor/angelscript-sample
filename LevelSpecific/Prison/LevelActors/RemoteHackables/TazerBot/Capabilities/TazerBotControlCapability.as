class UTazerBotControlCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default CapabilityTags.Add(PrisonTags::Prison);

	ATazerBot TazerBot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.IsHacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.IsHacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CapabilityInput::LinkActorToPlayerInput(TazerBot, TazerBot.HackingPlayer);

		if (!TazerBot.bTelescopeTutorialCompleted)
		{
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.Action = ActionNames::SecondaryLevelAbility;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
			TazerBot.HackingPlayer.ShowTutorialPromptWorldSpace(TutorialPrompt, TazerBot, TazerBot.TutorialAttachComp, FVector::ZeroVector, 0.0);
		}

		TazerBot.CrumbComponent.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		UPlayerHealthComponent::Get(TazerBot.HackingPlayer).OnStartDying.AddUFunction(this, n"OnPlayerStartDying");

		Outline::AddToPlayerOutlineActor(TazerBot, TazerBot.HackingPlayer, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(TazerBot, nullptr);

		TazerBot.HackingPlayer.RemoveTutorialPromptByInstigator(TazerBot);

		TazerBot.CrumbComponent.OverrideSyncRate(EHazeCrumbSyncRate::Standard);

		UPlayerHealthComponent::Get(TazerBot.HackingPlayer).OnStartDying.Unbind(this, n"OnPlayerStartDying");

		Outline::RemoveFromPlayerOutlineActor(TazerBot, TazerBot.HackingPlayer, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStartDying()
	{
		TazerBot.StartRespawning();
	}
}