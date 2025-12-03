struct FMedallionPlayerMergingZoomParams
{
	bool bNatural = false;
}

class UMedallionPlayerMergingZoomCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	bool bSetCamSettings = false;
	float32 StartFOV = 60;
	FHazeAcceleratedFloat AccFOV;

	UMedallionPlayerComponent MioMedallionComp;
	UMedallionPlayerComponent ZoeMedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MioMedallionComp = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		ZoeMedallionComp = UMedallionPlayerComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MedallionComp.IsMedallionCoopFlying())
			return false;

		if (!MedallionComp.bHasMergedFocus)
		 	return false;

		if (RefsComp.Refs == nullptr)
			return false;

		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMedallionPlayerMergingCompanionParams & DeactivationParams) const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
		{
			DeactivationParams.bNatural = true;
			return true;
		}

		if (MedallionComp.IsMedallionCoopFlying())
			return false;

		if (MedallionComp.bHasMergedFocus)
		 	return false;

		DeactivationParams.bNatural = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UCameraSettings Temp = UCameraSettings::GetSettings(Player);
		StartFOV = Temp.FOV.GetValue();
		AccFOV.SnapTo(StartFOV);
		MedallionComp.HighfiveZoomAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionPlayerMergingCompanionParams DeactivationParams)
	{
		// if (!DeactivationParams.bNatural)
		// 	return;
		if (bSetCamSettings)
		{
			UCameraSettings Temp = UCameraSettings::GetSettings(Player);
			if (Player.bIsControlledByCutscene)
				Temp.FOV.Clear(this, 0.0);
			else
				Temp.FOV.Clear(this, 2.0);
		}
		bSetCamSettings = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float HorizontalRange = MedallionConstants::Highfive::FOVStartApplyDistance - MedallionConstants::Highfive::FOVFinishApplyDistance;
		float FOV = MedallionConstants::Highfive::FOVOverride;
		
		if (!Math::IsNearlyEqual(HorizontalRange, 0.0))
		{
			FVector MioLocation = MioMedallionComp.GetPlayerLerpedRespawnLocation(DeltaTime);
			FVector ZoeLocation = ZoeMedallionComp.GetPlayerLerpedRespawnLocation(DeltaTime);

			const float HorizontalDistanceBetweenPlayers = MioLocation.Dist2D(ZoeLocation, FVector::UpVector);
			const float HorizontalClampedDistance = Math::Clamp(HorizontalDistanceBetweenPlayers, MedallionConstants::Highfive::FOVFinishApplyDistance, MedallionConstants::Highfive::FOVStartApplyDistance);

			const float NormalAspectRatio = 9.0 / 16.0;
			const float VerticalStartFOV = MedallionConstants::Highfive::FOVStartApplyDistance * NormalAspectRatio;
			const float VerticalFinishFOV = MedallionConstants::Highfive::FOVFinishApplyDistance * NormalAspectRatio;
			const float VerticalDistanceBetweenPlayers = Math::Abs(MioLocation.Z - ZoeLocation.Z);
			const float VerticalRange = VerticalStartFOV - VerticalFinishFOV;

			const float VerticalClampedDistance = Math::Clamp(VerticalDistanceBetweenPlayers, VerticalFinishFOV, VerticalStartFOV);
			const float HorizontalMergingAlpha = Math::Saturate((HorizontalClampedDistance - MedallionConstants::Highfive::FOVFinishApplyDistance) / HorizontalRange);
			const float VerticalMergingAlpha = Math::Saturate((VerticalClampedDistance - VerticalFinishFOV) / VerticalRange);
			
			const float UsedAlpha = Math::Max(HorizontalMergingAlpha, VerticalMergingAlpha);

			FOV = Math::Lerp(MedallionConstants::Highfive::FOVOverride, StartFOV, UsedAlpha);
			MedallionComp.HighfiveZoomAlpha = UsedAlpha;
		}

		if (HighfiveComp.IsInHighfiveFail() || Player.IsAnyCapabilityActive(n"GameOver"))
			AccFOV.AccelerateTo(MedallionConstants::Highfive::FailHighfiveFOVOverride, 2.0, DeltaTime);
		else
			AccFOV.AccelerateTo(FOV, 1.0, DeltaTime);
		
		UCameraSettings Temp = UCameraSettings::GetSettings(Player);
		Temp.FOV.Apply(AccFOV.Value, this, 0.0);
		bSetCamSettings = true;
	}
};