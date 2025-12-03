class UGameShowArenaAnnouncerSplineMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"MoveToPoint");
	default TickGroup = EHazeTickGroup::Movement;

	AGameShowArenaAnnouncer Announcer;
	float MaxMoveSpeed = 3000;

	bool bHasReachedTarget = false;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Announcer.TargetPoint == nullptr)
			return false;

		if (GameShowAnnouncer::DebugMovementLock.IsEnabled())
			return false;

		// FSplinePosition TargetSplinePos = Announcer.MovementSpline.Spline.GetSplinePositionAtSplineDistance(Announcer.TargetPoint.SplineDistance);
		// float MoveDist = Announcer.CurrentSplinePosition.DeltaToReachClosest(TargetSplinePos);
		// if (Math::Abs(MoveDist) < 50)
		// {
		// 	return false;
		// }

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Announcer.TargetPoint == nullptr)
			return true;

		if (GameShowAnnouncer::DebugMovementLock.IsEnabled())
			return true;

		if (bHasReachedTarget)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasReachedTarget = false;
		AccRotation.SnapTo(Announcer.ActorRotation);
		AccLocation.SnapTo(Announcer.ActorLocation);
		Announcer.CurrentSplinePosition = Announcer.MovementSpline.Spline.GetClosestSplinePositionToWorldLocation(Announcer.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FSplinePosition TargetSplinePos = Announcer.MovementSpline.Spline.GetSplinePositionAtSplineDistance(Announcer.TargetPoint.SplineDistance);
		float MoveDist = Announcer.CurrentSplinePosition.DeltaToReachClosest(TargetSplinePos);
		// Move at max speed when further away than stoppingdistance, start slowing down when closer than that
		float MoveAlpha = Math::Saturate(Math::NormalizeToRange(Math::Abs(MoveDist), 200, Announcer.StoppingDistance));
		MoveAlpha = Math::CircularOut(0, 1, MoveAlpha);
		Announcer.CurrentSplinePosition.Move(Math::Sign(MoveDist) * MaxMoveSpeed * MoveAlpha * DeltaTime);
		AccRotation.AccelerateTo(Announcer.CurrentSplinePosition.WorldRotation.Rotator(), 5, DeltaTime);
		if (ActiveDuration < 2)
			AccLocation.AccelerateTo(Announcer.CurrentSplinePosition.WorldLocation, 3.0, DeltaTime);
		else
			AccLocation.AccelerateTo(Announcer.CurrentSplinePosition.WorldLocation, 1.2, DeltaTime);
		Announcer.SetActorLocationAndRotation(AccLocation.Value, AccRotation.Value);
		//Announcer.SetActorLocationAndRotation(Announcer.CurrentSplinePosition.WorldLocation, Announcer.CurrentSplinePosition.WorldRotation);

#if EDITOR
		TEMPORAL_LOG(Announcer)
			.Value("SplineLocation", Announcer.CurrentSplinePosition.WorldLocation)
			.Value("SplineRotation", Announcer.CurrentSplinePosition.WorldRotation);
#endif
		// if (Math::Abs(MoveDist) < 50)
		// {
		// 	bHasReachedTarget = true;
		// }
	}
};