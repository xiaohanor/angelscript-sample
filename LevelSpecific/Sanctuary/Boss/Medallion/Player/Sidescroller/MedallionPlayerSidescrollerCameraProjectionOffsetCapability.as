class UMedallionPlayerSidescrollerCameraProjectionOffsetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;

	FHazeAcceleratedFloat AcceleratedProjectionOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		AcceleratedProjectionOffset.SnapTo(0.0);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		if (Player.IsAnyCapabilityActive(MedallionTags::MedallionScreenMerged))
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::None)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::None)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return true;
		if (MedallionComp.IsMedallionCoopFlying())
			return true;
		if (Player.IsAnyCapabilityActive(MedallionTags::MedallionScreenMerged))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedProjectionOffset.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AcceleratedProjectionOffset.SnapTo(1.0);
		auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
		ViewPoint.ClearOffCenterProjectionOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ProjectionAlpha;
		ProjectionAlpha = 1 - Math::Saturate((Game::Mio.GetHorizontalDistanceTo(Game::Zoe) - MedallionConstants::Merge::MergeScreenDistance) / MedallionConstants::Merge::ProjectionOffsetBlendDistance);

		float Signwards = Player.IsMio() ? -1.0 : 1.0;

		if (!Game::Mio.IsAnyCapabilityActive(MedallionTags::MedallionScreenMerged))
			AcceleratedProjectionOffset.AccelerateToWithStop(ProjectionAlpha, 0.5, DeltaTime, 0.01);
		else
			AcceleratedProjectionOffset.AccelerateToWithStop(0.0, 0.5, DeltaTime, 0.01);

		auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
		ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(AcceleratedProjectionOffset.Value * Signwards, 0.0), this);

		MedallionComp.ProjectionOffsetAlpha = AcceleratedProjectionOffset.Value;
	}
};