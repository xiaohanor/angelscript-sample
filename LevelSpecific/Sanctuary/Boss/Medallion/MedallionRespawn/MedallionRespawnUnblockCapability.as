namespace MedallionRespawnBlock
{
	const FName Layout2 = n"Layout2";
	const FName Layout3 = n"Layout3";
}

class UMedallionRespawnUnblockCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;
	UMedallionPlayerReferencesComponent RefsComp;

	EMedallionPhase LastPhase;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Sidescroller2)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::Merge3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase != LastPhase)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Sidescroller2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::Merge3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<AMedallionRespawnPointVolume> RespawnVolumes;
		for (AMedallionRespawnPointVolume RespawnVolume : RespawnVolumes.GetArray())
		{
			if (RefsComp.Refs.HydraAttackManager.Phase == RespawnVolume.EnabledPhase)
				RespawnVolume.EnableAfterStartDisabled();
		}
		LastPhase = RefsComp.Refs.HydraAttackManager.Phase;
	}
};