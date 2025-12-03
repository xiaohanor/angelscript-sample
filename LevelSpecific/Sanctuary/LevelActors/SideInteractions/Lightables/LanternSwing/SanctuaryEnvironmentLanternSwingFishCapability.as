struct FSanctuaryEnvironmentLanternSwingFishActivationParams
{
	FVector GrabLocation;
	FVector GrabForce;
}

class USanctuaryEnvironmentLanternSwingFishCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UDarkPortalTargetComponent TentacleTargetComponent;
	UDarkPortalResponseComponent TentacleRespComponent;
	bool bFishGrabbed = false;

	AHazePlayerCharacter Zoe;
	ADarkPortalActor PortalActor;
	float RandomDeactive = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Zoe = Game::Zoe;
		TentacleTargetComponent = UDarkPortalTargetComponent::Get(Owner);
		TentacleRespComponent = UDarkPortalResponseComponent::Get(Owner);
		TentacleRespComponent.OnGrabbed.AddUFunction(this, n"TentacleGrabbed");
		TentacleRespComponent.OnReleased.AddUFunction(this, n"TentacleReleased");
	}

	UFUNCTION()
	private void TentacleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bFishGrabbed = true;
		PortalActor = Portal;
	}

	UFUNCTION()
	private void TentacleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bFishGrabbed = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryEnvironmentLanternSwingFishActivationParams & Params) const
	{
		if (!bFishGrabbed)
			return false;
		if (DeactiveDuration < RandomDeactive)
			return false;

		Params.GrabLocation = TentacleTargetComponent.WorldLocation;
		FVector GrabDirection =  PortalActor.GetOriginLocation() - TentacleTargetComponent.WorldLocation;
		Params.GrabForce = GrabDirection.GetSafeNormal() * Math::RandRange(1500, 3500);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryEnvironmentLanternSwingFishActivationParams Params)
	{
		RandomDeactive = Math::RandRange(0.6, 1.5);
		FauxPhysics::ApplyFauxForceToActorAt(Owner, Params.GrabLocation, Params.GrabForce);
	}

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// }
};