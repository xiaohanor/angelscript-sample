class USanctuaryWellCameraFollowSplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UCameraUserComponent CameraUserComp;
	UCameraFollowSplineRotationComponent CameraFollowSplineRotationComp;
	UPlayerMovementComponent MoveComp;

	float LastInputTime = -1;
	const float ReturnDelay = 1.0;
	const float RampUpTime = 1.0;
	const float InterpSpeed = 1.5;
	const float LookAheadDistance = 200;
	float32 InitialFrameDeltaTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraFollowSplineRotationComp = UCameraFollowSplineRotationComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return false;

		if(!CameraFollowSplineRotationComp.HasSplineToFollow())
			return false;

		// If we are moving along the spline direction, immediately start adjusting
		if(IsMovingAlongSpline())
			return true;

		if(IsInputting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return true;

		if(!CameraFollowSplineRotationComp.HasSplineToFollow())
			return true;

		if(IsMovingAlongSpline())
			return false;

		if(IsInputting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialFrameDeltaTime = GetCapabilityDeltaTime();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActivelyInputting())
			LastInputTime = -1;
		else if(LastInputTime < 0)
			LastInputTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Intensity = Math::Saturate(ActiveDuration + InitialFrameDeltaTime / RampUpTime);

		const FRotator CurrentCameraRotation = CameraUserComp.GetDesiredRotation();
		const FRotator SplineRotation = GetSplineRotation(CurrentCameraRotation.ForwardVector);

		const FRotator NewCameraRotation = Math::RInterpTo(CurrentCameraRotation, SplineRotation, DeltaTime, InterpSpeed * Intensity);
		CameraUserComp.SetDesiredRotation(NewCameraRotation, this);
	}

	FRotator GetSplineRotation(FVector ViewForward) const
	{
		const float SplineDistance = CameraFollowSplineRotationComp.GetSpline().GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		FRotator Rotation =  CameraFollowSplineRotationComp.GetSpline().GetWorldRotationAtSplineDistance(SplineDistance + LookAheadDistance).Rotator();

		if(!CameraFollowSplineRotationComp.GetAlwaysFaceForward())
		{
			if(Rotation.ForwardVector.DotProduct(ViewForward) < 0)
			{
				// Flip!
				Rotation = FRotator::MakeFromAxes(-Rotation.ForwardVector, Rotation.RightVector, Rotation.UpVector);
			}
		}

		return Rotation;
	}

	bool IsActivelyInputting() const
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		return !AxisInput.IsNearlyZero(KINDA_SMALL_NUMBER);
	}

	bool IsInputting() const
	{
		if(IsActivelyInputting())
			return true;

		if(Time::GetGameTimeSince(LastInputTime) < ReturnDelay)
			return true;

		return false;
	}

	bool IsMovingAlongSpline() const
	{
		if(MoveComp.MovementInput.IsNearlyZero())
			return false;

		const FRotator CurrentCameraRotation = CameraUserComp.GetDesiredRotation();
		const FVector SplineForward = GetSplineRotation(CurrentCameraRotation.ForwardVector).ForwardVector;
		if(MoveComp.MovementInput.DotProduct(SplineForward) < 0)
			return false;

		return true;
	}
};