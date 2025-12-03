struct FTrainPlayerCameraFollowActivationParams
{
	ACoastTrainDriver ActivationTrainDriver;
}

class UTrainPlayerCameraFollowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

    default DebugCategory = CameraTags::Camera;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UCameraUserComponent CameraUser;
	UCoastTrainInheritMovementComponent TrainInheritMoveComp;
	UCoastTrainRiderComponent TrainRiderComp;

	ACoastTrainDriver CurrentTrainDriver;

	FSplinePosition ClosestSplinePos;

	FHazeAcceleratedRotator AccDeltaRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);

		TrainInheritMoveComp = UCoastTrainInheritMovementComponent::Get(Player);
		TrainRiderComp = UCoastTrainRiderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTrainPlayerCameraFollowActivationParams& Params) const
	{
		if(!CameraUser.CanControlCamera())
			return false;

		Params.ActivationTrainDriver = TrainRiderComp.GetRidingTrain(Player);
		if (Params.ActivationTrainDriver == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CameraUser.CanControlCamera())
			return true;

		if (!IsValid(CurrentTrainDriver))
			return true; // Train has streamed out		

		if(!CurrentTrainDriver.IsPlayerOnTrain(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTrainPlayerCameraFollowActivationParams Params)
	{
		CurrentTrainDriver = Params.ActivationTrainDriver;
		ClosestSplinePos = GetClosestSplinePositionOfClosestCart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float UndilatedDeltaTime = Time::CameraDeltaSeconds;

		if(CameraUser.CanControlCamera())
		{
			const float CameraFollowDuration = 0.75;

			FSplinePosition NewSplinePos = GetClosestSplinePositionOfClosestCart();
			FRotator DeltaRotation = NewSplinePos.WorldRotation.Rotator() - ClosestSplinePos.WorldRotation.Rotator();

			AccDeltaRotation.AccelerateTo(DeltaRotation, CameraFollowDuration, UndilatedDeltaTime);
			CameraUser.AddDesiredRotation(AccDeltaRotation.Value, this);

			ClosestSplinePos = NewSplinePos;
		}
	}

	FSplinePosition GetClosestSplinePositionOfClosestCart()
	{
		ACoastTrainCart ClosestCart = CurrentTrainDriver.GetCartClosestToPlayer(Player);
		return ClosestCart.FindClosestSplinePosition();
	}
};