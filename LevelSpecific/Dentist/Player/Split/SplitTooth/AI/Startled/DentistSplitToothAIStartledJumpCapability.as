
class UDentistSplitToothAIStartledJumpCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ADentistSplitToothAI SplitToothAI;

	UHazeMovementComponent MoveComp;
	UDentistToothMovementData Movement;

	float PreviousJumpHeight = 0;
	ADentistGooglyEye GooglyEye;
	float InitialEyeBoundaryRadius;
	float InitialEyePupilPercentage;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);

		MoveComp = SplitToothAI.MoveComp;
		Movement = MoveComp.SetupMovementData(UDentistToothMovementData);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SplitToothAI.Settings.StartledJumpDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousJumpHeight = 0;

		GooglyEye = UDentistGooglyEyeSpawnerComponent::Get(SplitToothAI).GooglyEye;
		InitialEyeBoundaryRadius = GooglyEye.BoundaryRadius;
		InitialEyePupilPercentage = GooglyEye.PupilPercentage;

		UDentistSplitToothAIEventHandler::Trigger_OnStartledJump(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GooglyEye.BoundaryRadius = InitialEyeBoundaryRadius;
		GooglyEye.PupilPercentage = InitialEyePupilPercentage;
		GooglyEye.UpdateMeshScale();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float JumpAlpha = Math::Saturate(ActiveDuration / SplitToothAI.Settings.StartledJumpDuration);
		TickMovement(JumpAlpha);
		TickMeshRotation(JumpAlpha);
		TickEyeScale(JumpAlpha);
	}

	void TickMovement(float JumpAlpha)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			float JumpHeight = SplitToothAI.Settings.StartledJumpHeightAlphaCurve.GetFloatValue(JumpAlpha);
			JumpHeight *= SplitToothAI.Settings.StartledJumpHeight;

			FVector Delta = FVector(0, 0, JumpHeight - PreviousJumpHeight);
			Movement.AddDelta(Delta);

			PreviousJumpHeight = JumpHeight;
		}
		else
		{
			Movement.ApplyLatestSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}

	void TickMeshRotation(float JumpAlpha)
	{
		float RollAngle = SplitToothAI.Settings.StartledJumpRollAlphaCurve.GetFloatValue(JumpAlpha);
		RollAngle *= Math::DegreesToRadians(SplitToothAI.Settings.StartledJumpRollAngleDegrees);
		SplitToothAI.SetMeshWorldRotation(SplitToothAI.ActorTransform.TransformRotation(FQuat(FVector::ForwardVector, RollAngle)), this);
	}

	void TickEyeScale(float JumpAlpha)
	{
		GooglyEye.BoundaryRadius = InitialEyeBoundaryRadius * SplitToothAI.Settings.StartledJumpEyeBoundaryRadiusMultiplierCurve.GetFloatValue(JumpAlpha);
		GooglyEye.PupilPercentage = InitialEyePupilPercentage * SplitToothAI.Settings.StartledJumpEyePupilPercentageMultiplierCurve.GetFloatValue(JumpAlpha);
		GooglyEye.UpdateMeshScale();
	}
};