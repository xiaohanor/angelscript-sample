class USwarmDroneAirductComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(Category = "SwarmAirduct|Intake", Meta = (MakeEditWidget), EditAnywhere)
	FVector IntakeLocation;
	default IntakeLocation = -FVector::ForwardVector * 100.0;


	UPROPERTY(Category = "SwarmAirduct|Travel", DisplayName = "Duration", EditAnywhere)
	float TravelDuration = 2.0;

	UPROPERTY(Category = "SwarmAirduct|Travel", DisplayName = "Spline", EditInstanceOnly)
	UHazeSplineComponent TravelSpline = nullptr;


	access AirductActor = private, ASwarmDroneAirduct;
	UPROPERTY(Category = "SwarmAirduct|Exhaust", Meta = (MakeEditWidget), EditAnywhere)
	access : AirductActor
	FTransform ExhaustTransform;

	UPROPERTY(Category = "SwarmAirduct|Exhaust", DisplayName = "Force", EditAnywhere)
	float ExhaustForce = 1000.0;


	UPROPERTY(Category = "SwarmAirduct|Camera", EditAnywhere)
	UHazeCameraSettingsDataAsset TravelCameraSettings;


	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter PlayerCharacter) const
	{
		if (!HasControl())
			return false;

		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(PlayerCharacter);
		if (SwarmDroneComponent == nullptr)
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		return true;
	}

	FVector GetWorldIntakeLocation() const
	{
		return WorldTransform.TransformPosition(IntakeLocation);
	}

	FTransform GetWorldExhaustTransform() const
	{
		return (ExhaustTransform * Owner.ActorTransform);
	}

	FVector GetExhaustLaunchVelocity() const
	{
		return (ExhaustTransform * Owner.ActorTransform).Rotation.ForwardVector * ExhaustForce;
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter SwarmDrone)
	{
		UPlayerSwarmDroneAirductComponent SwarmDroneAirductComponent = UPlayerSwarmDroneAirductComponent::Get(SwarmDrone);
		if (SwarmDroneAirductComponent == nullptr)
			return;

		SwarmDroneAirductComponent.CurrentAirductComponent = this;
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter SwarmDrone)
	{
		UPlayerSwarmDroneAirductComponent SwarmDroneAirductComponent = UPlayerSwarmDroneAirductComponent::Get(SwarmDrone);
		if (SwarmDroneAirductComponent == nullptr)
			return;

		if (SwarmDrone.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirductCapability))
			return;

		SwarmDroneAirductComponent.CurrentAirductComponent = nullptr;
	}
}