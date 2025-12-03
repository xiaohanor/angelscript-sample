class UGravityBikeFreeDriverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::PlayerTags::GravityBikeFreeDriver);
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UGravityBikeFreeDriverComponent DriverComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
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
		DriverComp.GetOrSpawnGravityBike();
		
		Player.ApplyCameraSettings(DriverComp.CameraSettings, 0.0, this, SubPriority = 100);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
            return;

        Player.Mesh.RequestLocomotion(GravityBikeFree::GravityBikeFreeDriverFeature, this);
	}
}