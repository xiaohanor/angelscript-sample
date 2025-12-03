
class UPerchOnPointCameraAssistType : UCameraAssistType
{
	// How fast we rotate
	UPROPERTY()
	float RotationDuration = 0;
	
	void Apply(float DeltaTime, float ScriptMultiplier, FCameraAssistSettingsData Settings,
	           FHazeActiveCameraAssistData& Data, FHazeCameraTransform& OutResult) const override
	{
		if(Settings.ActiveDuration < SMALL_NUMBER)
		{
			Data.DesiredRotation.SnapTo(OutResult.LocalDesiredRotation);
			Data.YawRotationSpeed.SnapTo(0);
		}

		FVector WorldInput = OutResult.ViewRotation.RotateVector(FVector(Settings.MovementInputRaw.Y, Settings.MovementInputRaw.X, 0));
		float InputMultiplier = Math::Lerp(0.5, 1, WorldInput.DotProductLinear(OutResult.ViewRotation.RightVector));
		float Multiplier = ScriptMultiplier * Settings.ContextualMultiplier * Settings.InputMultiplier * InputMultiplier;
		
		FRotator Target = Data.DesiredRotation.Value;
		const FRotator PrevRotation = Target;
		if(Multiplier > 0)
			Target = Data.DesiredRotation.AccelerateTo(OutResult.WorldToLocalRotation(OutResult.UserRotation), RotationDuration, DeltaTime * Multiplier);
		
		FRotator Diff = Target - PrevRotation;
		OutResult.AddLocalDesiredDeltaRotation(FRotator(0, Diff.Yaw, 0));

		float ControlRotationAlpha = 1 - OutResult.ViewRotation.ForwardVector.DotProductNormalized(OutResult.UserRotation.ForwardVector);
		OutResult.AddControlRotationMultiplier(Math::Lerp(1, 0.5, Math::Pow(ControlRotationAlpha, 2)));
	}
}

asset PerchOnPointCameraAssistStrong of UPerchOnPointCameraAssistType
{
	RotationDuration = 2;
}


class UPerchOnPointCameraAssistCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraChaseAssistance);
	default CapabilityTags.Add(CameraTags::CameraOptionalChaseAssistance);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 190;
    default DebugCategory = CameraTags::Camera;

	UPlayerPerchComponent PerchComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UCameraUserComponent User;
	UCameraAssistComponent AssistComp;
	UCameraUserSettings UserSettings;
	UCameraSettings CameraSettings;

	float InputAmountMultiplier = 0;
	float InputDelayTimeLeft = 0;
	FRotator PrevDeltaRotation = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchComp = UPlayerPerchComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);
		UserSettings = UCameraUserSettings::GetSettings(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsAnyCapabilityActive(PlayerMovementTags::Perch))
			return false;

		if(!Player.IsUsingCameraAssist())
			return false;

		if(CameraSettings.HasActiveKeepInView())
			return false;

		if(Player.HasAnyActivePointOfInterest())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.IsAnyCapabilityActive(PlayerMovementTags::Perch))
			return true;

		if(!Player.IsUsingCameraAssist())
			return true;

		if(CameraSettings.HasActiveKeepInView())
			return true;

		if(Player.HasAnyActivePointOfInterest())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		// Must be here since its not in the same sheet
		if(AssistComp == nullptr)
			AssistComp = UCameraAssistComponent::Get(Player);
		
		AssistComp.AddAssistEnabled(this);

		// We only give assist on strong settings
		AssistComp.ApplyAssistType(PerchOnPointCameraAssistStrong, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AssistComp.RemoveAssistEnabled(this);
		AssistComp.ClearAssistType(this);
		InputAmountMultiplier = 0;
		InputDelayTimeLeft = 0;
		PrevDeltaRotation = FRotator::ZeroRotator;
		Player.ClearSettingsByInstigator(this);
	}
};