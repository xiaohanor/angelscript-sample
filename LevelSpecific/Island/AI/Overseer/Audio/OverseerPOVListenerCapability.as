class UOverseerPOVListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::ProxyListenerBlocker);

	AAIIslandOverseer Overseer;
	AIslandOverseerPovCameraController CameraController;

	const float POVActivationDelay = 7.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto OverseerBoss = TListedActors<AAIIslandOverseer>().GetSingle();
		if(OverseerBoss == nullptr)
			return false;

		return OverseerBoss.PhaseComp.Phase == EIslandOverseerPhase::PovCombat;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		return Overseer.PhaseComp.Phase != EIslandOverseerPhase::PovCombat;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Overseer = TListedActors<AAIIslandOverseer>().GetSingle();
		CameraController = TListedActors<AIslandOverseerPovCameraController>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < POVActivationDelay)
			return;

		FTransform	POVListenerTransform = FTransform(CameraController.ActorForwardVector.ToOrientationRotator(), CameraController.ActorLocation);		
		Player.PlayerListener.SetWorldTransform(POVListenerTransform);			
	}
}