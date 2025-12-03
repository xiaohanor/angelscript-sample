class AMedallionHydraDeathVolume : ADeathVolume
{
	const FName MedallionPhaseDisabler = n"MedallionPhaseDisabler";
	default StartDisabledInstigator = MedallionPhaseDisabler;
	private UMedallionPlayerReferencesComponent RefsComp;

	UPROPERTY(EditDefaultsOnly)
	TArray<EMedallionPhase> EnabledDuringPhases;
	bool bPhaseEnabled = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (RefsComp == nullptr)
			RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		if (RefsComp.Refs == nullptr)
			return;
		
		bool bShouldBeEnabled = EnabledByPhase();
		if (bShouldBeEnabled && !bPhaseEnabled)
		{
			bPhaseEnabled = true;
			EnableDeathVolume(MedallionPhaseDisabler);
		}
		else if (!bShouldBeEnabled && bPhaseEnabled)
		{
			bPhaseEnabled = false;
			DisableDeathVolume(MedallionPhaseDisabler);
		}
	}

	private bool EnabledByPhase() const
	{
		for (EMedallionPhase Phase : EnabledDuringPhases)
		{
			if (RefsComp.Refs.HydraAttackManager.Phase == Phase)
				return true;
		}
		return false;
	}
};