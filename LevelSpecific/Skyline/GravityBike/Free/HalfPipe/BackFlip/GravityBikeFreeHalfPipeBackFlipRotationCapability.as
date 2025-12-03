class UGravityBikeFreeHalfPipeBackFlipRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeBackFlip);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeRotation);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;

	FQuat StartRotation;

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

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::BackFlip)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		if(ActiveDuration > GravityBikeFree::HalfPipe::BackFlipDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartRotation = GravityBike.ActorQuat;
		HalfPipeComp.AccRotation.Value = GravityBike.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HalfPipeComp.RotationState = EGravityBikeFreeHalfPipeRotationState::Aim;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / GravityBikeFree::HalfPipe::BackFlipDuration;
		Alpha = HalfPipeComp.Settings.BackFlipCurve.GetFloatValue(Alpha);

		FQuat Rotation = Math::RotatorFromAxisAndAngle(StartRotation.RightVector, Alpha * -180).Quaternion() * StartRotation;
		HalfPipeComp.AccRotation.AccelerateTo(Rotation, 0.2, DeltaTime);
	}
}