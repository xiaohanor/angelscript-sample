struct FSanctuaryCompanionAviationTutorialStartDeactivateParams
{
	bool bNatural = false;
	FVector Destination;
}

class USanctuaryCompanionAviationTutorialStartPlayerCapability : UHazePlayerCapability
{
	// Crumb 
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (AviationComp.GetIsAviationActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSanctuaryCompanionAviationTutorialStartDeactivateParams& Params) const
	{
		if (!CompanionAviation::bUseLevelSequenceSwoop && ActiveDuration < AviationComp.ActivateAviationDelay)
			return false;

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		FVector ToTarget;
		if (DestinationData.HasRuntimeSpline())
		{
			FSanctuaryCompanionAviationDestinationSplineData DestinationSplineData;
			DestinationData.GetSplineData(Player.ActorLocation, 0.0, DestinationSplineData);
			Params.Destination = DestinationSplineData.NextSplineLocation;
			Params.bNatural = true;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		{
			Player.AddMovementImpulseToReachHeight(AviationComp.Settings.StartAviationImpulseReachAdditionalHeight);
		}

		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSanctuaryCompanionAviationTutorialStartDeactivateParams Params)
	{
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if (!Params.bNatural)
			return;

		{
			const FVector ToTarget = Params.Destination - Player.ActorLocation;
			if (!Player.IsActorBeingDestroyed())
				Player.SmoothTeleportActor(Player.ActorLocation, FRotator::MakeFromXZ(ToTarget.GetSafeNormal(), FVector::UpVector), this, 0.0);
		}

		if (AviationComp.HasDestination())
			AviationComp.StartAviation();
	}
};