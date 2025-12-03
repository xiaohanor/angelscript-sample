struct FGravityBikeFreeDriverCenterViewCameraDeactivateParams
{
	bool bNatural = false;
};

/**
 * While CenterView is active, this will take that rotation and feed it into the GravityBikeFree camera system.
 */
class UGravityBikeFreeDriverCenterViewCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 105;

	UGravityBikeFreeDriverComponent DriverComp;
	UCenterViewPlayerComponent CenterViewComp;
	UCenterViewSettings CenterViewSettings;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUserComp;

	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();

		UCenterViewSettings::SetApplyPitchOffset(Player, false, this);
		UCenterViewSettings::SetMinimumLockOnDuration(Player, GravityBike.Settings.CameraInputDelay + CenterViewSettings.TurnDuration, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		if(!CenterViewComp.HasAppliedCenterViewThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeDriverCenterViewCameraDeactivateParams& Params) const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
		{
			Params.bNatural = true;
			return true;
		}

		if(!CenterViewComp.HasAppliedCenterViewThisFrame())
		{
			Params.bNatural = true;
			return true;
		}

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CameraDataComp.AccCameraRotation.SnapTo(CameraDataComp.GetInputOffsetAppliedToAccCameraRotation());
		CameraDataComp.ResetInputOffset();

		Player.BlockCapabilities(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeCamera, this);
		GravityBike.BlockCapabilities(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeDriverCenterViewCameraDeactivateParams Params)
	{
		Player.UnblockCapabilities(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeCamera, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeCamera, this);

		if(Params.bNatural)
		{
			// Prevent the input camera from kicking in
			CameraDataComp.NoInputDuration = GravityBike.Settings.CameraInputDelay;

			// Apply the input offset, just like the input capability
			const FQuat ForwardRotation = CameraDataComp.GetBikeForwardTargetRotation(GravityBike.Settings.CameraLeadAmount);
			CameraDataComp.ApplyInputOffset(CameraDataComp.AccCameraRotation.Value * ForwardRotation.Inverse());
			CameraDataComp.AccCameraRotation.SnapTo(ForwardRotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	private void TickControl(float DeltaTime)
	{
		CameraDataComp.AccCameraRotation.SnapTo(CameraUserComp.GetDesiredRotation().Quaternion());
		CameraDataComp.AccYawAxisRollOffset.AccelerateTo(0, GravityBike.Settings.CameraRollResetDuration, DeltaTime);
		CameraDataComp.ApplyDesiredRotation(this, true);
	}

	private void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
}