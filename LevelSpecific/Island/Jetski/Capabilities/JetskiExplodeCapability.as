class UJetskiExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Death);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Jetski.Driver.IsPlayerDead())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Jetski.Driver.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetski.bIsDestroyed = true;
		UJetskiEventHandler::Trigger_OnExplode(Jetski);
		Jetski.RemoveSoundDefs();

		Jetski.BlockCapabilities(CapabilityTags::Movement, this);
		Jetski.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Jetski.BlockCapabilities(CapabilityTags::Camera, this);

		Jetski.AddActorVisualsBlock(this);
		Jetski.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.RemoveActorVisualsBlock(this);
		Jetski.RemoveActorCollisionBlock(this);

		Jetski.UnblockCapabilities(CapabilityTags::Movement, this);
		Jetski.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Jetski.UnblockCapabilities(CapabilityTags::Camera, this);

		// if the level is being destroyed the following events/attachments can fail in some way.
		if (Jetski.IsActorBeingDestroyed())
			return;

		if(Jetski.bIsDestroyed)
			Jetski.AttachSoundDefs();
		
		Jetski.bIsDestroyed = false;
		UJetskiEventHandler::Trigger_OnRespawn(Jetski);
	}
};