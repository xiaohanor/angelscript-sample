struct FGravityBikeFreeDriverInputCameraDeactivateParams
{
	bool bNatural = false;
};

class UGravityBikeFreeDriverInputCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UGravityBikeWeaponUserComponent WeaponComp;
	
	AGravityBikeFree GravityBike;

	FRotator PreviousRotation;
	FRotator PreviousDesiredRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		if(!CameraDataComp.IsInputting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeDriverInputCameraDeactivateParams& Params) const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
		{
			Params.bNatural = true;
			return true;
		}

		const float LastFiredTime = WeaponComp.GetLastFireTime();
		if(Time::GetGameTimeSince(LastFiredTime) < GravityBike.Settings.CameraInputDelay)
		{
			// Keep input camera going while firing
			return false;
		}

		if(!CameraDataComp.IsInputting())
		{
			Params.bNatural = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(GravityBike.IsCapabilityTagBlocked(GravityBikeFree::Tags::GravityBikeFreeCameraInput))
		{
			CameraDataComp.NoInputDuration = BIG_NUMBER;
		}
		else
		{
			if (IsActivelyInputting())
				CameraDataComp.NoInputDuration = 0.0;
			else
				CameraDataComp.NoInputDuration += DeltaTime;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousRotation = GravityBike.ActorRotation;
		PreviousDesiredRotation = CameraDataComp.GetDesiredRotation();

		// Reset the input offset while using the input camera
		CameraDataComp.ResetInputOffset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeDriverInputCameraDeactivateParams Params)
	{
		if(Params.bNatural)
		{
			// Use an offset after we have applied input, so that we can smoothly fade it out over time
			const FQuat ForwardRotation = CameraDataComp.GetBikeForwardTargetRotation(GravityBike.Settings.CameraLeadAmount);
			CameraDataComp.ApplyInputOffset(CameraDataComp.AccCameraRotation.Value * ForwardRotation.Inverse());

			// Snap to the forward direction, since the input offset will be applied on top of this
			CameraDataComp.AccCameraRotation.SnapTo(ForwardRotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	private void TickControl(float DeltaTime)
	{
		// Follow player camera input
		FRotator DesiredRotation = CameraDataComp.GetDesiredRotation();

		if(GravityBike.Settings.bFollowBikeRotation)
		{
			FRotator DeltaRotation = GravityBike.ActorRotation - PreviousRotation;
			DeltaRotation = FRotator(0, DeltaRotation.Yaw, 0);
			DesiredRotation = DeltaRotation.Compose(DesiredRotation);
		}

		if(GravityBike.Settings.bSpeedUpIfInputtingIntoSteering)
		{
			const float SteeringInput = GravityBike.Input.Steering;
			const float YawInput = GravityBike.GetDriver().CameraInput.X;
			if(!Math::IsNearlyZero(SteeringInput) && !Math::IsNearlyZero(YawInput))
			{
				if(Math::Sign(SteeringInput) == Math::Sign(YawInput))
				{
					FQuat DesiredRotationDelta = (DesiredRotation.Quaternion() * PreviousDesiredRotation.Quaternion().Inverse());
					float TwistAngle = DesiredRotationDelta.GetTwistAngle(FVector::UpVector);
					TwistAngle *= Math::Abs(SteeringInput) * Math::Abs(YawInput) * GravityBike.Settings.SpeedUpIfInputtingIntoSteeringMultiplier;
					DesiredRotationDelta = FQuat(FVector::UpVector, TwistAngle);
					DesiredRotation = (DesiredRotationDelta * DesiredRotation.Quaternion()).Rotator();
				}
			}
		}

		CameraDataComp.AccCameraRotation.SnapTo(DesiredRotation.Quaternion());

		CameraDataComp.AccYawAxisRollOffset.AccelerateTo(
			GravityBike.AnimationData.AngularSpeedAlpha * -GravityBike.Settings.CameraRollMultiplier,
			GravityBike.Settings.CameraRollDuration,
			DeltaTime
		);

		CameraDataComp.ApplyDesiredRotation(this);
		
		CameraDataComp.ApplyCameraOffsetFromSpeed(DeltaTime);

		PreviousRotation = GravityBike.ActorRotation;
		PreviousDesiredRotation = DesiredRotation;
	}

	private void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}

	bool IsActivelyInputting() const
	{
		if(GravityBike.IsCapabilityTagBlocked(GravityBikeFree::Tags::GravityBikeFreeCameraInput))
			return false;
		
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		return !AxisInput.IsNearlyZero(0.001);
	}
}