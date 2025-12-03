class UGravityBikeFreeDriverFallingCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 135;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		if(!IsFalling())
			return false;

		if(CameraDataComp.IsInputting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return true;

		if(!IsFalling())
			return true;

		if(CameraDataComp.IsInputting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(MoveComp.IsOnAnyGround() || Owner.IsCapabilityTagBlocked(CapabilityTags::Movement))
			CameraDataComp.FallDuration = 0.0;
		else
			CameraDataComp.FallDuration += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		// Face camera in velocity dir when falling and not inputting
		FVector LookDir = MoveComp.Velocity.GetSafeNormal();

		switch(GravityBike.Settings.CameraFallMode)
		{
			case EGravityBikeFreeFallCameraMode::FaceVelocity:
				break;

			case EGravityBikeFreeFallCameraMode::FaceVelocityDown:
				if(LookDir.Z > 0)
					LookDir = LookDir.VectorPlaneProject(FVector::UpVector);
				break;

			case EGravityBikeFreeFallCameraMode::AlwaysLookDown:
				LookDir = LookDir.VectorPlaneProject(FVector::UpVector);
				LookDir.Normalize();
				LookDir.Z = -1;
				LookDir.Normalize();
				break;
		}

		FQuat VelocityRotation = FQuat::MakeFromXZ(LookDir, MoveComp.WorldUp);
		CameraDataComp.AccCameraRotation.AccelerateTo(VelocityRotation, GravityBike.Settings.CameraFallFollowDuration, DeltaTime);
		
		CameraDataComp.AccYawAxisRollOffset.AccelerateTo(
			GravityBike.AnimationData.AngularSpeedAlpha * -GravityBike.Settings.CameraRollMultiplier,
			GravityBike.Settings.CameraRollDuration,
			DeltaTime
		);

		CameraDataComp.ApplyDesiredRotation(this);
		
		CameraDataComp.ResetCameraOffsetFromSpeed();
	}

	void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}

	bool IsFalling() const
	{
		return CameraDataComp.FallDuration > GravityBike.Settings.CameraFallDelay;
	}
}