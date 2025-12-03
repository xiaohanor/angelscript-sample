class USanctuaryWeeperTopDownAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerAimingComponent AimingComp;
	USanctuaryWeeperTopDownPlayerComponent TopDownPlayerComp;
	USanctuaryWeeperArtifactUserComponent ArtifactUserComp;

	ASanctuaryWeeperArtifact Artifact;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimingComp = UPlayerAimingComponent::Get(Player);
		TopDownPlayerComp = USanctuaryWeeperTopDownPlayerComponent::Get(Player);
		ArtifactUserComp = USanctuaryWeeperArtifactUserComponent::Get(Player);
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
		
		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = true;

		AimingComp.StartAiming(this, AimingSettings);
		Player.ApplyAiming2DPlaneConstraint(FVector::UpVector, this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimingComp.StopAiming(this);
		Player.ClearAiming2DConstraint(this);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FAimingResult CurrentAim = AimingComp.GetAimingTarget(this);

		// if(ArtifactUserComp.Artifact != nullptr)
		// 	ArtifactUserComp.Artifact.ActorRotation = FRotator::MakeFromX(CurrentAim.AimDirection);

	}
};