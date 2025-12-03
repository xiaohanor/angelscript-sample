struct FDesertGrappleFishPlayerRidingDeactivateParams
{
	bool bShouldLaunch = false;
	bool bShouldApplyPOI = false;
}

struct FDesertGrappleFishPlayerRidingActivateParams
{
	ADesertGrappleFish GrappleFish;
}

class UDesertGrappleFishPlayerRidingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointPerch);
	default CapabilityTags.Add(CameraTags::UsableWhileInDebugCamera);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;
	default TickGroupSubPlacement = 10;

	UPlayerMovementComponent MoveComp;
	UDesertGrappleFishPlayerComponent PlayerComp;
	UPlayerPerchComponent PerchComp;

	UTeleportingMovementData MoveData;

	UDesertGrappleFishSplineCameraSettingsComponent CurrentCameraSettingsComp;

	FHazeAcceleratedVector AccGravityDirection;

	float EndJumpActiveDuration;

	float TimeWhenRespawned = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
		UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		TimeWhenRespawned = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDesertGrappleFishPlayerRidingActivateParams& Params) const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.GrappleFish == nullptr)
			return false;

		if (PlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return false;

		if (PlayerComp.bShouldDetachFromShark)
			return false;

		Params.GrappleFish = PlayerComp.GrappleFish;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDesertGrappleFishPlayerRidingDeactivateParams& Params) const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;

		if (PlayerComp.GrappleFish == nullptr)
			return true;

		if (PlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return true;

		if (PlayerComp.GrappleFish.bAllowManualLaunch && WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
		{
			Params.bShouldLaunch = true;
			return true;
		}

		if (PlayerComp.bShouldDetachFromShark)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDesertGrappleFishPlayerRidingActivateParams Params)
	{
		PlayerComp.GrappleFish = Params.GrappleFish;
		PlayerComp.LandscapeLevel = Params.GrappleFish.LandscapeLevel;
		Player.BlockCapabilities(BlockedWhileIn::Perch, this);
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);

		Player.ApplyCameraSettings(PlayerComp.GrappleFish.RidingCameraSettings, GrappleFishCamera::RidingCameraSettingsBlendInTime, this, EHazeCameraPriority::VeryHigh);

		FHazePointOfInterestFocusTargetInfo FocusInfo;

		// This contains all the possible settings for the clamped poi
		FApplyClampPointOfInterestSettings Settings;
		Settings.Duration = GrappleFishPOI::RidingPOIClampDuration;
		Settings.BlendInAccelerationType = GrappleFishPOI::RidingPOIBlendInAccelerationType;
		Settings.InputCounterForce = GrappleFishPOI::RidingPOIInputCounterForce;
		Settings.InputTurnRateMultiplier = GrappleFishPOI::RidingPOIInputTurnRateMultiplier;
		// Settings.TurnTime = 3;

		// This is the clamps that should be used
		FHazeCameraClampSettings PoiClamps;
		PoiClamps.ApplyClampsYaw(GrappleFishPOI::RidingPOIYawClamp.X, GrappleFishPOI::RidingPOIYawClamp.Y);
		PoiClamps.ApplyClampsPitch(GrappleFishPOI::RidingPOIPitchClamp.X, GrappleFishPOI::RidingPOIPitchClamp.Y);

		if (Time::GetGameTimeSince(TimeWhenRespawned) < 2)
		{
			Player.SetActorRotation(PlayerComp.GrappleFish.GrapplePointComp.WorldRotation);
			Player.SnapCameraBehindPlayer();
		}
		FocusInfo.SetFocusToComponent(PlayerComp.GrappleFish.POITarget);
		Player.ApplyClampedPointOfInterest(this, FocusInfo, Settings, PoiClamps, GrappleFishPOI::RidingPOIBlendInTime, EHazeCameraPriority::High);
		MoveComp.FollowComponentMovement(PlayerComp.GrappleFish.GrapplePointComp, this, EMovementFollowComponentType::Teleport);

		AccGravityDirection.SnapTo(MoveComp.GravityDirection);
		PlayerComp.GrappleFish.AttachRopeToPlayer();
		Player.PlayCameraShake(PlayerComp.GrappleFish.MovementShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDesertGrappleFishPlayerRidingDeactivateParams DeactivateParams)
	{
		PerchComp.StopPerching();
		Player.UnblockCapabilities(BlockedWhileIn::Perch, this);
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);

		if (DeactivateParams.bShouldLaunch)
		{
			MoveComp.UnFollowComponentMovement(this);
			PlayerComp.LaunchFromGrappleFish(true);
		}
		else if (PlayerComp.bShouldDetachFromShark)
		{
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
			Player.SetActorHorizontalVelocity(Player.ActorHorizontalVelocity * 0.5);
			PlayerComp.ChangeState(EDesertGrappleFishPlayerState::FinalJump);
		}

		if (!PlayerComp.bTriggerEndJump)
			ClearRidingCamera(GrappleFishCamera::RidingCameraSettingsBlendOutTime);

		PlayerComp.GrappleFish.DetachRopeFromPlayer();
	}

	void ClearRidingCamera(float BlendOutTime)
	{
		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);
		Player.StopCameraShakeByInstigator(this, false);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform NeckTransform = PlayerComp.GrappleFish.SharkMesh.GetSocketTransform(n"Spine3");
		FVector Forward = -NeckTransform.Rotation.Rotator().UpVector;
		FVector Up = NeckTransform.Rotation.Rotator().ForwardVector;

		PlayerComp.GrappleFish.GrapplePointComp.WorldLocation = NeckTransform.Location + Up * 155;
		PlayerComp.GrappleFish.GrapplePointComp.WorldRotation = FRotator::MakeFromXZ(Forward, Up);

		FVector MovementUp = PlayerComp.GrappleFish.GrapplePointComp.UpVector;

		// Clear camera settings earlier if we are going into endjump
		if (PlayerComp.bTriggerEndJump)
		{
			EndJumpActiveDuration += DeltaTime;
			MovementUp = Math::Lerp(Up, FVector::UpVector, Math::Saturate(Math::SmoothStep(0.8, 1, EndJumpActiveDuration / 1.0)));
			MovementUp.Normalize();
			ClearRidingCamera(1.0);
		}

		if (MoveComp.PrepareMove(MoveData, MovementUp))
		{
			if (HasControl())
			{
				if (!PlayerComp.bTriggerEndJump)
				{
					MoveData.SetRotation(PlayerComp.GrappleFish.GrapplePointComp.WorldRotation);
				}
				else
				{
					MoveData.SetRotation(FRotator::MakeFromXZ(Forward, MovementUp));
				}
				MoveData.IgnoreSplineLockConstraint();
			}
			else
				MoveData.ApplyCrumbSyncedRotationOnly();

			MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(
				PlayerComp.GrappleFish.GrapplePointComp.WorldLocation, FVector::ZeroVector);

			MoveComp.ApplyMove(MoveData);
		}
	}
};

asset GrappleFishDismountPOIClearOnInput of UCameraPointOfInterestClearOnInputSettings
{
	bClearDurationOverridesBlendIn = true;
	InputClearAngleThreshold = 25;
}