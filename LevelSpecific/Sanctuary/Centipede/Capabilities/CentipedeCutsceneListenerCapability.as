// Blocks centipede tag when generic cutscene block tag is used
class UCentipedeCutsceneListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default TickGroup = EHazeTickGroup::LastDemotable;

	bool bBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		bBlocked = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (bBlocked)
		{
			Player.UnblockCapabilities(CentipedeTags::Centipede, this);
			bBlocked = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.BlockCapabilities(CentipedeTags::Centipede, this);
		bBlocked = true;
	}
}