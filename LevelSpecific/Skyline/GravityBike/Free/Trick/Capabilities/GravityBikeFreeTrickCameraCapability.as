class UGravityBikeFreeTrickCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::TrickTags::GravityBikeFreeTrick);
	default CapabilityTags.Add(GravityBikeFree::TrickTags::GravityBikeFreeTrickCamera);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeTrickComponent TrickComp;

	AHazePlayerCharacter Player;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		TrickComp = UGravityBikeFreeTrickComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TrickComp.bHasPerformedTrick && !TrickComp.bIsPerformingTrick)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TrickComp.bHasPerformedTrick && !TrickComp.bIsPerformingTrick)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CameraDataComp.AccCameraRotation.Value = CameraUser.GetDesiredRotation().Quaternion();
		CameraUser.SetDesiredRotation(CameraDataComp.AccCameraRotation.Value.Rotator(), this);
	}
};