
class UPlayerTeenDragonGeckoClimbCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

    default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default TickGroupSubPlacement = 5;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	UTeenDragonTailGeckoClimbOrientationComponent OrientationComp;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedQuat AccCurrentYawAxis;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	float StartClampUp;
	float StartClampDown;

	bool bSettingsBlendedIn = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		OrientationComp = UTeenDragonTailGeckoClimbOrientationComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GeckoClimbComp.CameraTransitionAlpha < KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GeckoClimbComp.CameraTransitionAlpha < KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		AccCurrentYawAxis.SnapTo(FVector::UpVector.ToOrientationQuat());

		auto CameraSettings = UCameraSettings::GetSettings(Player);
		FHazeActiveCameraClampSettings StartClampSettings;
		CameraSettings.Clamps.GetClamps(StartClampSettings);

		StartClampDown = StartClampSettings.PitchDown.Value;
		StartClampUp = StartClampSettings.PitchUp.Value;

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyComponentBasedCenterOffsetWithRotation(OrientationComp);
		ClampSettings.ApplyComponentBasedCenterOffset(OrientationComp);
		UCameraSettings::GetSettings(Player).Clamps.Apply(ClampSettings, this, SubPriority = 65);

		GeckoClimbComp.bWallCameraIsOn = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.ClearCameraSettingsByInstigator(this, ClimbSettings.CameraSettingsBlendOutTime);

		if(bSettingsBlendedIn)
		{
			Player.ClearCameraSettingsByInstigator(n"CameraClimbSettings", ClimbSettings.CameraSettingsBlendOutTime);
			bSettingsBlendedIn = false;
		}

		GeckoClimbComp.bWallCameraIsOn = false;
		GeckoClimbComp.bWallCameraHasTransitioned = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RollCamera(Time::CameraDeltaSeconds);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyComponentBasedCenterOffsetWithRotation(OrientationComp);

		float LerpedClampUp = Math::Lerp(StartClampUp, 0, GeckoClimbComp.CameraTransitionAlpha);
		float LerpedClampDown = Math::Lerp(StartClampDown, 80, GeckoClimbComp.CameraTransitionAlpha);
		ClampSettings.ApplyClampsPitch(LerpedClampUp, LerpedClampDown);
		ClampSettings.ApplyClampsYaw(180 - (90 * GeckoClimbComp.CameraTransitionAlpha), 180 - (90 * GeckoClimbComp.CameraTransitionAlpha));
		UCameraSettings::GetSettings(Player).Clamps.Apply(ClampSettings, this, SubPriority = 65);

		TEMPORAL_LOG(Player, "Wall Climb")
			.Value("Camera transition alpha", GeckoClimbComp.CameraTransitionAlpha)
			.Value("Camera transition alpha target", GeckoClimbComp.CameraTransitionAlphaTarget)
			.Value("Camera transition speed", GeckoClimbComp.CameraTransitionSpeed)
		;

		if(bSettingsBlendedIn)
		{
			if(GeckoClimbComp.CameraTransitionAlphaTarget < GeckoClimbComp.CameraTransitionAlpha)
			{
				Player.ClearCameraSettingsByInstigator(n"CameraClimbSettings", ClimbSettings.CameraSettingsBlendOutTime);
				bSettingsBlendedIn = false;
			}
		}
		else
		{
			if(GeckoClimbComp.CameraTransitionAlphaTarget > GeckoClimbComp.CameraTransitionAlpha)
			{
				Player.ApplyCameraSettings(TailDragonComp.ClimbCameraSettings, ClimbSettings.CameraSettingsBlendInTime, n"CameraClimbSettings", SubPriority = 65);
				bSettingsBlendedIn = true;
			}
		}
	}

	void RollCamera(float CameraDeltaTime)
	{
		FVector UpVector = FVector::UpVector;
		FVector Normal = Player.ActorUpVector;
		if(TailDragonComp.IsClimbing())
		{
			Normal = GeckoClimbComp.GetWallNormal();
			UpVector = GeckoClimbComp.CurrentClimbParams.ClimbComp.UpVector;
		}
		else if(GeckoClimbComp.bIsJumpingOntoWall)
		{
			Normal = GeckoClimbComp.WallEnterClimbParams.WallNormal;
			UpVector = GeckoClimbComp.WallEnterClimbParams.ClimbComp.UpVector;
		}
		FVector HorizontalToWall = Normal.CrossProduct(UpVector);
		FVector VerticalToWall = HorizontalToWall.CrossProduct(Normal);

		FVector NewYaw = VerticalToWall.RotateAngleAxis(-90 * ClimbSettings.CameraRollMultiplier , HorizontalToWall);
		
		AccCurrentYawAxis.AccelerateTo(NewYaw.ToOrientationQuat(), 1.0, CameraDeltaTime);

		FVector TransitionedYawAxis = Math::Lerp(UpVector, AccCurrentYawAxis.Value.ForwardVector, GeckoClimbComp.CameraTransitionAlpha);
		CameraUser.SetYawAxis(TransitionedYawAxis, this);

		TEMPORAL_LOG(Player, "Wall Climb")
			.DirectionalArrow("Camera: Wall Normal", Player.ActorLocation, Normal * 500, 5, 40, FLinearColor::DPink)
			.DirectionalArrow("Camera: Climb Up", Player.ActorLocation, UpVector * 500, 5, 40, FLinearColor::LucBlue)
			.DirectionalArrow("Camera: Vertical to Wall", Player.ActorLocation, VerticalToWall * 500, 5, 40, FLinearColor::Blue)
			.DirectionalArrow("Camera: Horizontal to Wall", Player.ActorLocation, HorizontalToWall * 500, 5, 40, FLinearColor::Green)
			.DirectionalArrow("Camera: New Yaw", Player.ActorLocation, NewYaw * 500, 5, 40, FLinearColor::Teal)
			.DirectionalArrow("Camera: Transitioned Yaw Axis", Player.ActorLocation, TransitionedYawAxis * 500, 5, 40, FLinearColor::Purple)
			.DirectionalArrow("Camera: Acc Current Yaw Axis", Player.ActorLocation, AccCurrentYawAxis.Value.ForwardVector * 500, 5, 40, FLinearColor::White)
			.Value("Camera: TransitionAlpha", GeckoClimbComp.CameraTransitionAlpha)
		;
	}
}
