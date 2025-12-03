class UCutsceneSwarmDroneUpdateMeshRotationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	ACutsceneSwarmDrone SwarmDrone;
	UDroneMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDrone = Cast<ACutsceneSwarmDrone>(Owner);
		MovementSettings = UDroneMovementSettings::GetSettings(SwarmDrone);
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
	void TickActive(float DeltaTime)
	{
		const FVector AngularVelocity =  SwarmDrone.ActorVelocity.CrossProduct(FVector::UpVector);
		float RotationSpeed = (AngularVelocity.Size() / SwarmDrone.SwarmDroneVisualRadius);
		RotationSpeed = Math::Clamp(RotationSpeed, -MovementSettings.RollMaxSpeed, MovementSettings.RollMaxSpeed);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		SwarmDrone.SwarmGroupMeshComponent.AddWorldRotation(DeltaQuat);
	}
}