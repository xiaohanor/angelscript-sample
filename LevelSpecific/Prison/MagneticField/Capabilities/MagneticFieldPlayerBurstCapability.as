struct FMagneticFieldPlayerBurstActivateParams
{
	FVector ForceOrigin;
	TMap<AActor, FMagneticFieldFilteredResult> FilteredOverlaps;
}

struct FMagneticFieldPlayerBurstDeactivateParams
{
	bool bTransitionedToPush = false;
};

/**
 * Charges magnetic field, and then releases a burst impulse.
 * If PrimaryLevelAbility is held, a force is applied to magnetic objects in proximity.
 */
class UMagneticFieldPlayerBurstCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(PrisonTags::ExoSuit);
	default CapabilityTags.Add(ExoSuitTags::MagneticField);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UMagneticFieldPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagneticFieldPlayerBurstActivateParams& Params) const
	{
		if (!PlayerComp.HasFinishedCharging())
			return false;

		const FVector ForceOrigin = PlayerComp.GetMagneticFieldCenterPoint();
		const FOverlapResultArray Overlaps = PlayerComp.QueryNearbyOverlaps(ForceOrigin);
		Params.ForceOrigin = ForceOrigin;
		Params.FilteredOverlaps = PlayerComp.FilterNearbyOverlapsForMagnetize(Overlaps);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagneticFieldPlayerBurstDeactivateParams& Params) const
	{
		if(PlayerComp.GetChargeState() == EMagneticFieldChargeState::Pushing)
		{
			Params.bTransitionedToPush = true;
			return true;
		}

		Params.bTransitionedToPush = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagneticFieldPlayerBurstActivateParams Params)
	{
		PlayerComp.SetChargeState(EMagneticFieldChargeState::Burst);
		UMagneticFieldEventHandler::Trigger_FinishedCharging(Player);

		{
			Player.ApplyCameraSettings(PlayerComp.FinishedChargingCameraSettings, 0.5, PlayerComp, SubPriority = 60);
			
			FHazeCameraImpulse CamImpulse;
			CamImpulse.CameraSpaceImpulse = FVector(-1800.0, 0.0, 0.0);
			CamImpulse.Dampening = 0.4;
			CamImpulse.ExpirationForce = 180.0;
			Player.ApplyCameraImpulse(CamImpulse, PlayerComp);

			for (AHazePlayerCharacter CurPlayer : Game::Players)
				CurPlayer.PlayWorldCameraShake(PlayerComp.BurstCameraShake, PlayerComp, PlayerComp.GetMagneticFieldCenterPoint(), MagneticField::GetTotalRadius() * 0.75, MagneticField::GetTotalRadius() * 0.5, 1.0, 4.0);
		}

		PlayerComp.BurstMagnetizeNearbyActors(Params.ForceOrigin, Params.FilteredOverlaps);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagneticFieldPlayerBurstDeactivateParams Params)
	{
		if(!Params.bTransitionedToPush)
		{
			// If we did not successfully transition to push, reset.
			PlayerComp.ResetCharge();
		}
	}
}