class UGravityBikeFreeHalfPipeAimRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeAim);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeRotation);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return false;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Aim)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		if(HalfPipeComp.GetJumpAlpha() > 0.7)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HalfPipeComp.AccRotation.Value = GravityBike.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HalfPipeComp.RotationState = EGravityBikeFreeHalfPipeRotationState::Land;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DirToCenter = HalfPipeComp.JumpData.GetJumpCenterLocation() - GravityBike.ActorLocation;
		DirToCenter.Normalize();

		FVector Up = (HalfPipeComp.JumpData.ToLocation - HalfPipeComp.JumpData.FromLocation).GetSafeNormal();

		FQuat Rotation = FQuat::MakeFromXZ(DirToCenter, Up);
		HalfPipeComp.AccRotation.AccelerateTo(Rotation, 1, DeltaTime);
	}
}