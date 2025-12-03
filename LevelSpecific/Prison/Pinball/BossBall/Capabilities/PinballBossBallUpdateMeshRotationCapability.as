class UPinballBossBallUpdateMeshRotationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBossBall BossBall;
	UHazeMovementComponent MoveComp;
	UPinballBallComponent BallComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		BallComp = UPinballBallComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector DesiredUp = MoveComp.HasGroundContact() ? MoveComp.GetGroundContact().ImpactNormal : MoveComp.WorldUp;
		const float Radius = BallComp.GetRadius();
		FVector AngularVelocity = MoveComp.Velocity / Radius;

		AngularVelocity =  MoveComp.Velocity.CrossProduct(DesiredUp);
		AngularVelocity.Z *= -1.0;	// Z direction needs to be flipped.

		const FQuat DeltaQuat = FQuat::MakeFromEuler(AngularVelocity * DeltaTime);
		BossBall.BallMesh.AddWorldRotation(DeltaQuat);	
	}
};