class UGravityBikeFreeHalfPipeLandRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeLand);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeRotation);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;

	FQuat StartRotation;
	float StartDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return false;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Land)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartRotation = GravityBike.ActorQuat;
		StartDistance = HalfPipeComp.DistanceAlongTrajectory;
		HalfPipeComp.AccRotation.Value = GravityBike.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = (HalfPipeComp.DistanceAlongTrajectory - StartDistance) / (HalfPipeComp.JumpData.JumpTrajectoryDistance - StartDistance);

		FVector DirOutFromCenter = GravityBike.ActorLocation - HalfPipeComp.JumpData.GetJumpCenterLocation();
		DirOutFromCenter = DirOutFromCenter.VectorPlaneProject(HalfPipeComp.JumpData.GetJumpTangent());
		DirOutFromCenter.Normalize();

		FQuat TargetRotation = FQuat::MakeFromXZ(MoveComp.Velocity, HalfPipeComp.JumpData.GetTargetNormal());
		TargetRotation = FQuat(TargetRotation.RightVector, Math::DegreesToRadians(-30)) * TargetRotation;
		FQuat Rotation = FQuat::Slerp(StartRotation, TargetRotation, Alpha);

		HalfPipeComp.AccRotation.AccelerateTo(Rotation, 0.2, DeltaTime);
	}
}