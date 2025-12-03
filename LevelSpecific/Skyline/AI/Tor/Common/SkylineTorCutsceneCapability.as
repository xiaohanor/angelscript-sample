
class USkylineTorCutsceneCapability : UHazeCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Owner.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Owner.bIsControlledByCutscene)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.RemoveActorCollisionBlock(this);
	}
}