struct FSanctuaryEnvironmentLanternSwingBirdActivationParams
{
	FVector Location;
	FVector Force;
}

class USanctuaryEnvironmentLanternSwingBirdCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	ULightBirdResponseComponent LightBirdRespComponent;
	bool bBirdAttached = false;

	AHazePlayerCharacter Mio;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mio = Game::Mio;
		LightBirdRespComponent = ULightBirdResponseComponent::Get(Owner);
		LightBirdRespComponent.OnAttached.AddUFunction(this, n"BirdAttached");
	}

	UFUNCTION()
	private void BirdAttached()
	{
		bBirdAttached = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryEnvironmentLanternSwingBirdActivationParams & Params) const
	{
		if (!bBirdAttached)
			return false;
		AAISanctuaryLightBirdCompanion Birb = LightBirdCompanion::GetLightBirdCompanion();
		if (Birb == nullptr)
			return false;
		if (Birb.MoveComp == nullptr)
			return false;
		Params.Force = Birb.MoveComp.GetVelocity().GetSafeNormal() * Math::RandRange(1500, 3500);
		Params.Location = Birb.ActorLocation;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryEnvironmentLanternSwingBirdActivationParams Params)
	{
		FauxPhysics::ApplyFauxForceToActorAt(Owner, Params.Location, Params.Force);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Mio.HasControl())
		{
			ULightBirdUserComponent BirbComp = ULightBirdUserComponent::Get(Mio);
			BirbComp.SetCompanionState(ELightBirdCompanionState::Follow);
		}

		bBirdAttached = false;
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// }
};