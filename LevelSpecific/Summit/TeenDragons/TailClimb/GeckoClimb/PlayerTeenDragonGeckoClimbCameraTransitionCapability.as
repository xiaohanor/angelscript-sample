
class UPlayerTeenDragonGeckoClimbCameraTransitionCapability : UHazePlayerCapability
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

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FRotator StartRotation;
	FRotator TargetRotation;

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
		if(!GeckoClimbComp.bWallCameraIsOn)
			return false;

		if(GeckoClimbComp.bWallCameraHasTransitioned)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > ClimbSettings.LandOnWallStartCameraTransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);

		StartRotation = CameraUser.ControlRotation;
		FVector TargetForward = Player.ActorForwardVector.RotateAngleAxis(ClimbSettings.LandOnWallCameraTransitionPitchDownDegrees, Player.ActorRightVector);
		TargetRotation = FRotator::MakeFromXZ(TargetForward, Player.ActorUpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		
		GeckoClimbComp.bWallCameraHasTransitioned = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / ClimbSettings.LandOnWallStartCameraTransitionDuration;
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2);

		FRotator Rotation = Math::LerpShortestPath(StartRotation, TargetRotation, Alpha);
		CameraUser.SetDesiredRotation(Rotation, this);
	}
}
