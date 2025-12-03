/**
 * While Mio hacks the hackable gears:
 * - Activate the SplineFollowCamera on Mio
 * - Set ViewSize to Large for Zoe
 */
class UHackableGearsMioHackingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHackableGearsManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AHackableGearsManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Game::Mio.ActivateCamera(Manager.SplineFollowCameraActor.Camera, 5.0, this, EHazeCameraPriority::High);
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Medium);

		Game::Mio.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Timer::SetTimer(this,n"BlendCam",2,false,0,0);
	}

	UFUNCTION()
	private void BlendCam()
	{
		//Game::Mio.ActivateCamera(Manager.SplineFollowCameraActor.Camera, 4.0, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Mio.DeactivateCameraByInstigator(this, 2);
		Game::Zoe.ClearViewSizeOverride(this);

		Game::Mio.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Timer::ClearTimer(this,n"BlendCam");
	}
};