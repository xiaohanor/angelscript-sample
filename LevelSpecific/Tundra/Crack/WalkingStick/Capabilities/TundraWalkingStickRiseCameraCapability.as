class UTundraWalkingStickRiseCameraCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::PostWork;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Camera);

	FTransform OriginalRelatvieCameraTransform;
	FRotator OriginalCameraWorldRotation;
	bool bDone = false;
	bool bInAdditionalActiveDuration = false;
	//float PreviousWalkingStickHipZ;

	const float RiseDuration = 4.36;
	const float AdditionalActiveDuration = 3.3;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::Rising)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		OriginalRelatvieCameraTransform = WalkingStick.RisingCamera.RelativeTransform;
		bDone = false;
		bInAdditionalActiveDuration = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / RiseDuration;
		if(Alpha >= 1.0 && !bInAdditionalActiveDuration)
		{
			Alpha = 1.0;
			bInAdditionalActiveDuration = true;
			OriginalCameraWorldRotation = WalkingStick.RisingCamera.WorldRotation;
		}

		if((ActiveDuration - RiseDuration) / AdditionalActiveDuration >= 1.0)
		{
			bDone = true;
		}

		//WalkingStick.RisingCamera.WorldLocation = WalkingStick.Mesh.GetSocketTransform(n"Hips").TransformPosition(OriginalRelatvieCameraTransform.Location);

		if(bInAdditionalActiveDuration)
		{
			//WalkingStick.RisingCamera.WorldRotation = OriginalCameraWorldRotation;
		}
	}
}