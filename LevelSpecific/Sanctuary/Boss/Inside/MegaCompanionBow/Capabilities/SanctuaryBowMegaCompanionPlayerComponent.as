namespace SanctuaryInsideMegaCompanions
{
	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Activate Inside Mega Companions", Category = "Sanctuary|Boss")
	void BP_ActivateMegaCompanions()
	{
		USanctuaryBowMegaCompanionPlayerComponent MioComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Game::Mio);
		MioComp.ActivateMegaCompanions();
		USanctuaryBowMegaCompanionPlayerComponent ZoeComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Game::Zoe);
		ZoeComp.ActivateMegaCompanions();
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Sanctuary Deactivate Inside Mega Companions", Category = "Sanctuary|Boss")
	void BP_DeactivateMegaCompanions()
	{
		USanctuaryBowMegaCompanionPlayerComponent MioComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Game::Mio);
		MioComp.DeactivateMegaCompanions();
		USanctuaryBowMegaCompanionPlayerComponent ZoeComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Game::Zoe);
		ZoeComp.DeactivateMegaCompanions();
	}
}

class USanctuaryBowMegaCompanionPlayerComponent : UActorComponent
{
	bool bMegaCompanionsActivated = false;

	void ActivateMegaCompanions()
	{
		bMegaCompanionsActivated = true;
	}

	void DeactivateMegaCompanions()
	{
		bMegaCompanionsActivated = false;
	}
};