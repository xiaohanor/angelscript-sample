asset PinballGravityFollowCameraMovementSettings of UPinballMovementSettings
{
	MinSlopeAngle = 0;
	MinimumSpeedToDecelerate = 200;
	bDecelerateOnSlopes = true;
	SlopeDecelerateSpeed = 1000;
}

class UPinballGravityFollowCamera : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UHazeMovementComponent MoveComp;
	UCameraUserComponent PaddleCameraUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		PaddleCameraUserComp = UCameraUserComponent::Get(Pinball::GetPaddlePlayer());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Pinball::ShouldGravityFollowCameraDown())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Pinball::ShouldGravityFollowCameraDown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.ApplySettings(PinballGravityFollowCameraMovementSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);

		MoveComp.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveComp.OverrideGravityDirection(FMovementGravityDirection::TowardsDirection(Pinball::GetGravityDirection(Pinball::GetWorldUp())), this);
	}
};