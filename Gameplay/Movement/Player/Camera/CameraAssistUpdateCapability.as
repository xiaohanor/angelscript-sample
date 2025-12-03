
class UCameraAssistUpdateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::CameraChaseAssistance);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100000; // really needs to be last of all the movements
    default DebugCategory = CameraTags::Camera;

	UCameraAssistComponent AssistComponent;
	UPlayerCameraAssistSettings AssistSettings;
	UCameraSettings CameraSettings;
	UControlRotationSettings ControlRotationSettings;
	UCameraAssistType PreviousAssistType;
	float InputMultiplier = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AssistComponent = UCameraAssistComponent::Get(Player);
		AssistSettings = UPlayerCameraAssistSettings::GetSettings(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
		ControlRotationSettings = UControlRotationSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return false;

		if(!AssistComponent.GetAssistType().IsA(UCameraFollowAssistSettings))
			return false;

		if(!AssistComponent.IsAssistEnabled())
			return false;

		if(CameraSettings.ChaseAssistFactor.Value < SMALL_NUMBER)
			return false;

		if (!Player.IsUsingGamepad())
			return false;

		if(AssistComponent.GetAssistType() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return true;

		if(!AssistComponent.GetAssistType().IsA(UCameraFollowAssistSettings))
			return true;
		
		if(!AssistComponent.IsAssistEnabled())
			return true;

		if(CameraSettings.ChaseAssistFactor.Value < SMALL_NUMBER)
			return true;

		if (!Player.IsUsingGamepad())
			return true;

		if(AssistComponent.GetAssistType() == nullptr)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InputMultiplier = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FCameraAssistSettingsData& Settings = AssistComponent.ActiveAssistSettings;
		Settings.AssistType = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float OriginalDeltaTime)
	{
		const float DeltaTime = Time::GetCameraDeltaSeconds();

		FCameraAssistSettingsData& Settings = AssistComponent.ActiveAssistSettings;

		Settings.AssistType = AssistComponent.GetAssistType();
		Settings.ActiveDuration = ActiveDuration;
		Settings.MovementInputRaw = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		Settings.InputSensitivity = Player.GetSensitivity(EHazeSensitivityType::Yaw);
		// Settings.FollowSensitivity = Player.GetCameraFollowSensitivity();
		Settings.UserVelocity = Player.ActorVelocity;
		Settings.UserWorldUp = Player.MovementWorldUp;

		const FTransform ViewTransform = Player.GetViewTransform();
		Settings.CurrentViewLocation = ViewTransform.Location;
		Settings.CurrentViewRotation = ViewTransform.Rotator();

		// Stop the assist when we give input
		Settings.CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if(!Settings.CameraInput.IsNearlyZero())
			InputMultiplier = 0;
		else
			InputMultiplier = Math::FInterpConstantTo(InputMultiplier, 1, DeltaTime, 1 / AssistSettings.CameraAssistRegainAfterInputTime);

		float Alpha = InputMultiplier / 1.0;
		Alpha = AssistSettings.CameraAssistMultiplierAfterInput.GetFloatValue(Alpha, Alpha);
		Settings.InputMultiplier = Alpha;
		Settings.ContextualMultiplier = AssistComponent.ContextualMultiplier.Get();	
	}
};
