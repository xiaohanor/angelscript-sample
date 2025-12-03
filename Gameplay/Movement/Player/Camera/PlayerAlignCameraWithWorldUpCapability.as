
class UPlayerAlignCameraWithWorldUpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraAlignWithWorldUp);
	
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default TickGroupOrder = 100;

	UCameraUserComponent CameraUser;
	UHazeMovementComponent Movement;
	FHazeAcceleratedRotator UpOrientation;

	UPlayerCameraSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		CameraUser.OnSnapped.AddUFunction(this, n"OnCameraSnapped");
		Movement = UHazeMovementComponent::Get(Player);

		Settings = UPlayerCameraSettings::GetSettings(Player);
	}

	UFUNCTION()
	private void OnCameraSnapped()
	{
		FVector UpVector = Movement.GetWorldUp();
		UpOrientation.SnapTo(FRotator::MakeFromZX(UpVector, Player.ActorForwardVector));

		if (!IsBlocked())
			CameraUser.SetYawAxis(UpOrientation.Value.UpVector, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Movement == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Movement == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector UpVector = Movement.GetWorldUp();
		UpOrientation.SnapTo(FRotator::MakeFromZX(UpVector, Player.ActorForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraUser.SetYawAxis(FVector::UpVector, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector UpVector = Movement.GetWorldUp();
		UpOrientation.AccelerateTo(FRotator::MakeFromZX(UpVector, UpOrientation.Value.ForwardVector), Settings.AlignCameraWithWorldUpDuration, DeltaTime);
		CameraUser.SetYawAxis(UpOrientation.Value.UpVector, this);
	}
};