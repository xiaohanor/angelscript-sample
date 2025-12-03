
class UCameraAssistUpdateNewCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::CameraChaseAssistance);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100000; // really needs to be last of all the movements
    default DebugCategory = CameraTags::Camera;

	UCameraAssistComponent AssistComponent;
	UPlayerCameraAssistSettings AssistSettings;
	UCameraSettings CameraSettings;
	UCameraAssistType PreviousAssistType;
	float InputMultiplier = 0;

	// New
	UCameraUserComponent CameraUserComp;
	UPlayerMovementComponent MoveComp;
	float LastStandStillTime = 0;
	FHazeAcceleratedQuat AccVerticalAxis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AssistComponent = UCameraAssistComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AssistSettings = UPlayerCameraAssistSettings::GetSettings(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return false;

		if(!AssistComponent.GetAssistType().IsA(UCameraFollowAssistTypeNew))
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

		if(!AssistComponent.GetAssistType().IsA(UCameraFollowAssistTypeNew))
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

		if(MoveComp.IsOnWalkableGround())
			AccVerticalAxis.SnapTo(FQuat::MakeFromZ(MoveComp.GroundContact.Normal));
		else
			AccVerticalAxis.SnapTo(FQuat::MakeFromZ(MoveComp.WorldUp));
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

		Settings.bApplyYaw = !Player.IsCapabilityTagBlocked(CameraTags::CameraChaseAssistanceYaw);
		Settings.bApplyPitch = !Player.IsCapabilityTagBlocked(CameraTags::CameraChaseAssistancePitch);

		Settings.AssistType = AssistComponent.GetAssistType();
		Settings.Settings = UPlayerCameraAssistSettings::GetSettings(Player);
		Settings.CameraUserSettings = UCameraUserSettings::GetSettings(Player);
		
		Settings.ActiveDuration = ActiveDuration;

		Settings.MovementInputRaw = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		if(!Settings.MovementInputRaw.IsNearlyZero())
			Settings.LastMovementInputTime = Time::RealTimeSeconds;
		else
			Settings.LastNoMovementInputTime = Time::RealTimeSeconds;

		Settings.InputSensitivity = Player.GetSensitivity(EHazeSensitivityType::Yaw);

		Settings.UserVelocity = Player.ActorVelocity;
		Settings.UserWorldUp = Player.MovementWorldUp;
		Settings.ControlRotation = FRotator::MakeFromZX(CameraUserComp.ActiveCameraYawAxis, CameraUserComp.ControlRotation.ForwardVector);

		if(MoveComp.IsOnWalkableGround())
		{
			// Grounded
			Settings.bIsGrounded = true;

			FVector GroundNormal = MoveComp.GroundContact.Normal;
			if(MoveComp.GroundContact.ImpactNormal.DotProduct(MoveComp.WorldUp) > GroundNormal.DotProduct(MoveComp.WorldUp))
				GroundNormal = MoveComp.GroundContact.ImpactNormal;

			AccVerticalAxis.AccelerateTo(FQuat::MakeFromZ(GroundNormal), Settings.Settings.GroundNormalAccelerateDuration, DeltaTime);
			Settings.VerticalAxis = AccVerticalAxis.Value.UpVector;
		}
		else
		{
			// Airborne
			Settings.bIsGrounded = false;

			AccVerticalAxis.AccelerateTo(FQuat::MakeFromZ(MoveComp.WorldUp), Settings.Settings.WorldUpAccelerateDuration, DeltaTime);
			Settings.VerticalAxis = AccVerticalAxis.Value.UpVector;
		}

		const FTransform ViewTransform = Player.GetViewTransform();
		Settings.CurrentViewLocation = ViewTransform.Location;
		Settings.CurrentViewRotation = ViewTransform.Rotator();

		Settings.CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if(!Settings.CameraInput.IsNearlyZero())
		{
			Settings.LastCameraInputTime = Time::RealTimeSeconds;
			Settings.LastCameraInputFrame = Time::FrameNumber;
		}
		else
		{
			Settings.LastNoCameraInputTime = Time::RealTimeSeconds;
		}

		if(AssistSettings.CameraAssistRegainAfterInputTime > 0)
		{
			// Stop the assist when we give input
			if(!Settings.CameraInput.IsNearlyZero())
				InputMultiplier = 0;
			else
				InputMultiplier = Math::FInterpConstantTo(InputMultiplier, 1, DeltaTime, 1 / AssistSettings.CameraAssistRegainAfterInputTime);
		}
		else
		{
			InputMultiplier = 1;
		}

		if(AssistSettings.RegainAfterMovingTime > 0)
		{
			if(Settings.MovementInputRaw.IsNearlyZero() && Player.ActorHorizontalVelocity.IsNearlyZero(100))
			{
				LastStandStillTime = Time::GameTimeSeconds;
			}
			else
			{
				if(Time::GetGameTimeSince(LastStandStillTime) < AssistSettings.RegainAfterMovingTime)
				{
					InputMultiplier = 0;
				}
			}
		}

		float Alpha = InputMultiplier / 1.0;
		Alpha = AssistSettings.CameraAssistMultiplierAfterInput.GetFloatValue(Alpha, Alpha);
		Settings.InputMultiplier = Alpha;
		Settings.ContextualMultiplier = AssistComponent.ContextualMultiplier.Get();

		const FTransform ControlTransform(Settings.ControlRotation);
		Settings.LocalUserVelocity = ControlTransform.InverseTransformVectorNoScale(Settings.UserVelocity);
		Settings.LocalUserRotation = ControlTransform.InverseTransformRotation(Player.ActorRotation);
		Settings.LocalUserWorldUp = ControlTransform.InverseTransformVectorNoScale(Settings.UserWorldUp);

		Settings.LocalViewRotation = ControlTransform.InverseTransformRotation(Settings.CurrentViewRotation);
		Settings.LocalVerticalAxis = ControlTransform.InverseTransformVectorNoScale(Settings.VerticalAxis);
	}
};
