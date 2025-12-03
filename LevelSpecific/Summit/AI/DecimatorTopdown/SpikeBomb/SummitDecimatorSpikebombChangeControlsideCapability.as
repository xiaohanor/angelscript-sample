class USummitDecimatorSpikebombChangeControlsideCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::ControlSideSwitch);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	USummitMeltComponent MeltComp;
	USummitDecimatorSpikeBombComponent SpikeBombComp;
	UHazeActorRespawnableComponent RespawnComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpikeBombComp = USummitDecimatorSpikeBombComponent::Get(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		SpikeBombComp.bIsLaunchable = false;
		if (Owner.IsCapabilityTagBlocked(CapabilityTags::Movement))
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		// We want fast reaction on Mio's side while melting. Later switch to Zoe when melted.
		Owner.SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MeltComp.bMelted)
			return false;

		if (!MoveComp.IsOnAnyGround())
			return false;

		// Prevent repeated activations
		if (SpikeBombComp.bIsLaunchable)
			return false;
				
		if (Network::IsGameNetworked() && Owner.HasControl() && Game::Zoe.HasControl())
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
		 // We want fast reaction on Zoe's side after melting. Later reset to Mio in Unspawn.
		Owner.SetActorControlSide(Game::Zoe);		

		// Prevent movement jitter, both sides location should be nearly +same
		Owner.BlockCapabilitiesExcluding(CapabilityTags::Movement, n"ProjectileMovement", this);

		 // Since we are switching control side, we want to guarantee that spikebomb is not launched just before control has been switched on both sides.
		SpikeBombComp.bIsLaunchable = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Print("Deactivated");
	}
};

