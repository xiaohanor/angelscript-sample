struct FDesertGrappleFishCameraYawActivationParams
{
	ADesertGrappleFish GrappleFish;
}

class UDesertGrappleFishPlayerCameraYawCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default TickGroup = EHazeTickGroup::AfterGameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UCameraUserComponent CameraUser;
	UDesertGrappleFishPlayerComponent PlayerComp;

	ADesertGrappleFish GrappleFish;
	FVector YawAxis;

	FHazeAcceleratedVector AccYawAxis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDesertGrappleFishCameraYawActivationParams& Params) const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.GrappleFish == nullptr)
			return false;

		Params.GrappleFish = PlayerComp.GrappleFish;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;
		
		if (PlayerComp.GrappleFish == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDesertGrappleFishCameraYawActivationParams Params)
	{
		GrappleFish = Params.GrappleFish;
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		AccYawAxis.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerComp.State == EDesertGrappleFishPlayerState::Riding)
		{
			FVector2D GrappleFishRollRange = FVector2D(-GrappleFishVisuals::MaxRollAmount, GrappleFishVisuals::MaxRollAmount);
			FVector2D CameraRollRange = FVector2D(-GrappleFishCamera::RidingCameraMaxRoll, GrappleFishCamera::RidingCameraMaxRoll);
			float Roll = Math::GetMappedRangeValueClamped(GrappleFishRollRange, CameraRollRange, GrappleFish.SharkMesh.RelativeRotation.Roll);
			if (GrappleFishCamera::bRidingCameraRollInSharkRollDirection)
				Roll *= -1;
			YawAxis = GrappleFish.ActorUpVector.RotateAngleAxis(Roll, GrappleFish.ActorForwardVector);
			AccYawAxis.AccelerateTo(YawAxis, 0.25, DeltaTime);
		}
		else
		{
			YawAxis = Math::VInterpTo(YawAxis, Player.ActorUpVector, DeltaTime, GrappleFishCamera::RidingCameraDismountUnrollInterpSpeed);
			AccYawAxis.AccelerateTo(YawAxis, 0.1, DeltaTime);
		}

		CameraUser.SetYawAxis(AccYawAxis.Value.GetSafeNormal(), this);
	}
};