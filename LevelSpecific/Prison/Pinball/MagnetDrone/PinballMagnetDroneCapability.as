class UPinballMagnetDroneCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(Pinball::Tags::Pinball);

	UPinballMagnetDroneComponent PinballComp;
	UPinballBallComponent BallComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PinballComp = UPinballMagnetDroneComponent::Get(Player);
		BallComp = UPinballBallComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Owner);
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
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}
}