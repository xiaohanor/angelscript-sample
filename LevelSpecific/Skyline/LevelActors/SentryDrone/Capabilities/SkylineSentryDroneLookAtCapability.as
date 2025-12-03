class USkylineSentryDroneLookAtCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneLookAt");

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneSettings::GetSettings(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();

		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SentryDrone.LookAtTarget.Get() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SentryDrone.LookAtTarget.Get() == nullptr)
			return true;

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
		FVector LookAtDirection = (SentryDrone.LookAtTarget.Get().ActorCenterLocation - SentryDrone.ActorLocation).GetSafeNormal();

		FVector Torque = SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorForwardVector.CrossProduct(LookAtDirection) * Settings.LookAtTorqueScale)
					   + SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector.CrossProduct(SentryDrone.MovementWorldUp) * Settings.LookAtTorqueScale)
					   - SentryDrone.AngularVelocity * Settings.LookAtAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;
	}
}