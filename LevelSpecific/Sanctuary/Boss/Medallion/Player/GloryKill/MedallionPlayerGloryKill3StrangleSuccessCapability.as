class UMedallionPlayerGloryKill3StrangleSuccessCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 60;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerGloryKillComponent OtherPlayerGloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		OtherPlayerGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player.OtherPlayer);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::Strangle)
			return false;
		if (GloryKillComp.SyncedStrangle.Value < 1.0 - KINDA_SMALL_NUMBER)
			return false;
		if (OtherPlayerGloryKillComp.SyncedStrangle.Value < 1.0 - KINDA_SMALL_NUMBER)
			return false;
		if (RefsComp.Refs == nullptr)
			return false;

		bool bDecidingPlayer = (Player.IsMio() && HasControl());
		if (!bDecidingPlayer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GloryKillComp.SetGloryKillState(EMedallionGloryKillState::ExecuteSequence, this);
		OtherPlayerGloryKillComp.SetGloryKillState(EMedallionGloryKillState::ExecuteSequence, this);
		RefsComp.Refs.GloryKillCirclingSpotTemp.MedallionHide();
	}
};