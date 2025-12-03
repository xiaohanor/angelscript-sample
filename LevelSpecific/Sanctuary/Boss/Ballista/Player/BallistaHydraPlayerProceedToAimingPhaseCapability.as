struct FBallistaHydraPlayerProceedToAimingPhaseData
{
	ASanctuaryHydraKillerBallista InteractingBallista;
}

struct FBallistaHydraPlayerProceedToAimingPhaseDeactivationData
{
	bool bCompleted = false;
}

class UBallistaHydraPlayerProceedToAimingPhaseCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;
	UMedallionPlayerReferencesComponent Refs;
	UPlayerInteractionsComponent MioInteracting;
	UPlayerInteractionsComponent ZoeInteracting;

	ASanctuaryHydraKillerBallista Ballista;
	bool bCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Refs = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MioInteracting = UPlayerInteractionsComponent::GetOrCreate(Game::Mio);
		ZoeInteracting = UPlayerInteractionsComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBallistaHydraPlayerProceedToAimingPhaseData & Params) const
	{
		if (Network::IsGameNetworked() && !Network::HasWorldControl())
			return false;
		if (!Network::IsGameNetworked() && Player.IsZoe())
			return false;
		if (Refs.Refs == nullptr)
			return false;
		if (MioInteracting.ActiveInteraction == nullptr)
			return false;
		if (ZoeInteracting.ActiveInteraction == nullptr)
			return false;
		ASanctuaryHydraKillerBallista InteractingBallista = Cast<ASanctuaryHydraKillerBallista>(MioInteracting.ActiveInteraction.Owner);
		if (InteractingBallista == nullptr)
			return false;
		Params.InteractingBallista = InteractingBallista;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBallistaHydraPlayerProceedToAimingPhaseDeactivationData & Params) const
	{
		if (bCompleted)
		{
			Params.bCompleted = true;
			return true;
		}
		if (MioInteracting.ActiveInteraction == nullptr)
			return true;
		if (ZoeInteracting.ActiveInteraction == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBallistaHydraPlayerProceedToAimingPhaseData Params)
	{
		AAISanctuaryLightBirdCompanion Birb = LightBirdCompanion::GetLightBirdCompanion();
		Birb.CompanionComp.bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = false;
		AAISanctuaryDarkPortalCompanion Fishy = DarkPortalCompanion::GetDarkPortalCompanion();
		Fishy.CompanionComp.bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = false;

		bCompleted = false;
		Ballista = Params.InteractingBallista;
		Params.InteractingBallista.OnMashCompleted.AddUFunction(this, n"MashCompleted");
		if (Refs.Refs.HydraAttackManager.Phase <= EMedallionPhase::BallistaNearBallista1)
			Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaPlayersAiming1);
		else if (Refs.Refs.HydraAttackManager.Phase <= EMedallionPhase::BallistaNearBallista2)
			Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaPlayersAiming2);
		else if (Refs.Refs.HydraAttackManager.Phase <= EMedallionPhase::BallistaNearBallista3)
			Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaPlayersAiming3);
	}

	UFUNCTION()
	private void MashCompleted()
	{
		bCompleted = true;
		{
			if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming1)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaArrowShot1);
			else if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming2)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaArrowShot2);
			else if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming3)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaArrowShot3);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBallistaHydraPlayerProceedToAimingPhaseDeactivationData Params)
	{
		if (!Params.bCompleted)
		{
			if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming1)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista1);
			else if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming2)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista2);
			else if (Refs.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming3)
				Refs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::BallistaNearBallista3);
		}
		bCompleted = false;
		Ballista = nullptr;
	}
};