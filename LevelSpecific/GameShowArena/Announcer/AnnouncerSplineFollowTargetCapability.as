class UGameShowArenaAnnouncerSplineFollowTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FollowTarget");
	default TickGroup = EHazeTickGroup::Movement;

	AGameShowArenaAnnouncer Announcer;

	float SplineRadius = 3500;
	float CenterDeadZoneFrac = 0.3;
	float CenterDeadZoneSpeed = 0;

	float InnerDeadZoneFrac = 0.6;
	float InnerDeadZoneSpeed = 2000;

	float MaxMoveSpeed = 3000;

	float MovementDistanceThreshold = 50;

	float GetSplineMovement(float DeltaTime) const
	{
		AHazeActor Target = Announcer.TargetPlayer;
		if (Announcer.TargetOverride.Get() != nullptr)
			Target = Announcer.TargetOverride.Get();

		FSplinePosition TargetSplinePos = Announcer.MovementSpline.Spline.GetClosestSplinePositionToWorldLocation(Target.ActorLocation);
		float MoveDist = Announcer.CurrentSplinePosition.DeltaToReachClosest(TargetSplinePos);
		if (Math::Abs(MoveDist) < MovementDistanceThreshold)
			return 0;
		float PlayerToCenterDist = Announcer.MovementSpline.ActorCenterLocation.Dist2D(Target.ActorLocation);
		float RadiusFrac = PlayerToCenterDist / SplineRadius;
		
		float MoveSpeedForZone;
		if (RadiusFrac < CenterDeadZoneFrac)
			MoveSpeedForZone = CenterDeadZoneSpeed;
		else if (RadiusFrac < InnerDeadZoneFrac)
			MoveSpeedForZone = InnerDeadZoneSpeed;
		else
			MoveSpeedForZone = MaxMoveSpeed;

		// Move at max speed when further away than stoppingdistance, start slowing down when closer than that
		float MoveAlpha = Math::Saturate(Math::NormalizeToRange(Math::Abs(MoveDist), 0, Announcer.StoppingDistance));
		MoveAlpha = Math::CircularOut(0, 1, MoveAlpha);

		return Math::Sign(MoveDist) * MoveSpeedForZone * MoveAlpha * DeltaTime;
			
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Announcer.bFollowTarget)
			return false;

		if (GameShowAnnouncer::DebugMovementLock.IsEnabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Announcer.bFollowTarget)
			return true;

		if (GameShowAnnouncer::DebugMovementLock.IsEnabled())
			return false;

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
		Announcer.CurrentSplinePosition.Move(GetSplineMovement(DeltaTime));
		Announcer.SetActorLocationAndRotation(Announcer.CurrentSplinePosition.WorldLocation, Announcer.CurrentSplinePosition.WorldRotation);
	}
};