class UCameraPanFocusCameraSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MaximumDistance = 500.0;
	UPROPERTY()
	float InterpolationSpeed = 2.0;
	UPROPERTY()
	float ReturnSpeed = 2.0;
	UPROPERTY()
	float DelayBeforeReturn = 0.0;
}

class UCameraPanFocusCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default TickGroup = EHazeTickGroup::Gameplay;
	UCameraUserComponent CameraUser;
	UCameraPanFocusCameraSettings PanSettings;

	FVector Offset;
	float LastInputTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		PanSettings = UCameraPanFocusCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CameraUser.ActiveCamera == nullptr)
			return false;
		auto Camera = Cast<AFocusCameraActor>(CameraUser.ActiveCamera.Owner);
		if (Camera != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CameraUser.ActiveCamera == nullptr)
			return true;
		auto Camera = Cast<AFocusCameraActor>(CameraUser.ActiveCamera.Owner);
		if (Camera == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Offset = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MaxDistance = PanSettings.MaximumDistance;
		float InterpSpeed = PanSettings.InterpolationSpeed;

		auto Camera = Cast<AFocusCameraActor>(CameraUser.ActiveCamera.Owner);
		Camera.FocusTargetComponent.ApplyAdditiveViewOffset(
			Player, Offset, this
		);

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		if (Input.Size() >= 0.1)
		{
			Offset = Math::VInterpConstantTo(
				Offset,
				FVector(0.0, Input.X, Input.Y) * MaxDistance,
				DeltaTime, MaxDistance * InterpSpeed
			);
			LastInputTime = Time::GameTimeSeconds;
		}
		else if (Time::GetGameTimeSince(LastInputTime) > PanSettings.DelayBeforeReturn)
		{
			Offset = Math::VInterpConstantTo(
				Offset,
				FVector::ZeroVector,
				DeltaTime, MaxDistance * InterpSpeed
			);
		}
	}
};