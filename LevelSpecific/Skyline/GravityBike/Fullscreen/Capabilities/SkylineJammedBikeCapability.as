class USkylineJammedBikeCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	USkylineJammedBikeComponent JammedBikeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JammedBikeComp = USkylineJammedBikeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (JammedBikeComp.bHasFinishedAccelerateTutorial)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (JammedBikeComp.bHasFinishedAccelerateTutorial)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto GravityBike = GravityBikeSpline::GetGravityBike();
		GravityBike.BlockCapabilities(GravityBikeSpline::Tags::GravityBikeSpline, this);
		GravityBike.BlockEnemySlowRifleFire.Add(this);

		GravityBikeWhip::GetPlayer().BlockCapabilities(GravityBikeWhip::Tags::GravityBikeWhip, this);
		GravityBikeBlade::GetPlayer().BlockCapabilities(GravityBikeBlade::Tags::GravityBikeBlade, this);

		JammedBikeComp.OnSkylineJammedBikeTutorialActivateEnemy.Broadcast();

		Player.ActivateCamera(JammedBikeComp.CameraActor, 0.0, this);

		GravityBike.AttachToComponent(JammedBikeComp.PodiumActor.RotationPivotComp, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto GravityBike = GravityBikeSpline::GetGravityBike();
		GravityBike.UnblockCapabilities(GravityBikeSpline::Tags::GravityBikeSpline, this);
		GravityBike.BlockEnemySlowRifleFire.Remove(this);
		
		GravityBikeWhip::GetPlayer().UnblockCapabilities(GravityBikeWhip::Tags::GravityBikeWhip, this);
		GravityBikeBlade::GetPlayer().UnblockCapabilities(GravityBikeBlade::Tags::GravityBikeBlade, this);

		GravityBike.SetSpline(JammedBikeComp.SplineActor);

		GravityBike.DetachFromActor();

		Player.DeactivateCameraByInstigator(this, 4.0);
	}
};