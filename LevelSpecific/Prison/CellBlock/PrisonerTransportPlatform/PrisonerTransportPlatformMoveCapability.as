class UPrisonerTransportPlatformMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	APrisonerTransportPlatform TransportPlatform;

	int LoopCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TransportPlatform = Cast<APrisonerTransportPlatform>(Owner);
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
		// Snap the loop count to prevent events from triggering immediately
		float DistanceAlongSpline = 0;
		GetState(DistanceAlongSpline, LoopCount);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveAlongSpline(DeltaTime);
		SpinPropeller(DeltaTime);
		HoverWiggle();
	}

	void GetState(float&out OutDistanceAlongSpline, int&out OutLoopCount) const
	{
		const float TimeSinceStart = Time::PredictedGlobalCrumbTrailTime;
		const float DistanceAlongSpline = TransportPlatform.StartDistanceAlongSpline + (TimeSinceStart * TransportPlatform.MoveSpeed);

		OutDistanceAlongSpline = DistanceAlongSpline % TransportPlatform.SplineActor.Spline.SplineLength;
		OutLoopCount = Math::FloorToInt(DistanceAlongSpline / TransportPlatform.SplineActor.Spline.SplineLength);
	}

	void MoveAlongSpline(float DeltaTime)
	{
		if (!TransportPlatform.bMoving)
			return;

		float DistanceAlongSpline = 0;
		int CurrentLoops = 0;
		GetState(DistanceAlongSpline, CurrentLoops);

		bool bTeleport = false;
		while(LoopCount < CurrentLoops)
		{
			TransportPlatform.ReachedEndOfSpline();

			LoopCount++;
			bTeleport = true;
		}

		FTransform SplineTransform = TransportPlatform.SplineActor.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);

		FRotator Rotation = SplineTransform.Rotator();
		Rotation.Pitch = Math::Clamp(Rotation.Pitch, -8.0, 8.0);
		SplineTransform.SetRotation(Rotation);

		TransportPlatform.SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation, bTeleport);
	}

	void SpinPropeller(float DeltaTime)
	{
		TransportPlatform.PropellerRoot.AddLocalRotation(FRotator(0.0, 200.0 * DeltaTime, 0.0));
	}

	void HoverWiggle()
	{
		float Time = Time::PredictedGlobalCrumbTrailTime + TransportPlatform.HoverTimeOffset;

		float YOffset = Math::Sin(Time * TransportPlatform.HoverOffsetSpeed.Y) * TransportPlatform.HoverOffsetRange.Y;
		float ZOffset = Math::Sin(Time * TransportPlatform.HoverOffsetSpeed.Z) * TransportPlatform.HoverOffsetRange.Z;
		FVector Offset = (FVector(0.0, YOffset, ZOffset));

		float Roll = Math::DegreesToRadians(Math::Sin(Time * TransportPlatform.HoverRollSpeed) * TransportPlatform.HoverRollRange);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time * TransportPlatform.HoverPitchSpeed) * TransportPlatform.HoverPitchRange);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

		TransportPlatform.PlatformRoot.SetRelativeLocationAndRotation(Offset, Rotation);
	}
};