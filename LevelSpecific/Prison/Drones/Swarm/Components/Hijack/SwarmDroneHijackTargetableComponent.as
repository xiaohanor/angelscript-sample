event void FSwarmHijackStartEvent(FSwarmDroneHijackParams HijackParams);
event void FSwarmHijackStopEvent();

class USwarmDroneHijackTargetableComponent : UTargetableComponent
{
	default TargetableCategory = SwarmDroneTags::SwarmDroneHijackTargetableCategory;

	UPROPERTY(EditAnywhere)
	FSwarmHijackTargetableSettings HijackSettings;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	private FVector PlayerSnapLocation;
	default PlayerSnapLocation = FVector::ForwardVector * 200.0 - FVector::UpVector * 50;

	// Area where bots will jump to
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	private FVector2D DiveAreaSize = FVector2D(50, 100);

	UPROPERTY()
	FSwarmHijackStartEvent OnHijackStartPrepareDiveEvent;

	UPROPERTY()
	FSwarmHijackStartEvent OnHijackStartEvent;

	UPROPERTY()
	FSwarmHijackStopEvent OnHijackStopEvent;
	
	private AHazePlayerCharacter HijackPlayer = nullptr;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		SnapPlayerSnapLocationToGround();
	}

	private void SnapPlayerSnapLocationToGround()
	{
		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(SwarmDrone::Radius);

		const float TraceOffset = 150.0;
		FVector Start = GetWorldPlayerSnapLocation() + FVector::UpVector * TraceOffset;
		FVector End = GetWorldPlayerSnapLocation() - FVector::UpVector * TraceOffset;
		FHitResultArray HitResults = Trace.QueryTraceMulti(Start, End);
		for (auto HitResult : HitResults)
		{
			if (HitResult.bStartPenetrating)
				continue;

			if (!HitResult.IsValidBlockingHit(true))
				continue;

			if (!HitResult.Component.HasTag(n"Walkable"))
				continue;

			// Debug::DrawDebugSphere(HitResult.Location, 37.5, Duration = 1);

			FVector RelativePlayerLocation = WorldTransform.InverseTransformPositionNoScale(HitResult.Location + FVector::UpVector);
			PlayerSnapLocation = RelativePlayerLocation;
		}
	}
#endif

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		const float VisibleRange = HijackSettings.AimRange * 3.0;
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		Targetable::ApplyTargetableRange(Query, HijackSettings.AimRange);
		Targetable::ScoreLookAtAim(Query, true, false);
		Targetable::ApplyVisualProgressFromRange(Query, VisibleRange, HijackSettings.AimRange);

		Targetable::ScoreCameraTargetingInteraction(Query);

		// Check angle
		FVector PlayerToHijackable = (WorldLocation - Query.PlayerLocation).ConstrainToPlane(Query.PlayerWorldUp).GetSafeNormal();
		float Angle = Math::RadiansToDegrees(PlayerToHijackable.AngularDistanceForNormals(-ForwardVector));
		// if (Angle > HijackSettings.MaxActivationAngle)
		// 	return false;

		if(Game::Mio.ActorLocation.Z < WorldLocation.Z - 500)
			return false;

		return true;
	}

	void StartPrepareDive(FSwarmDroneHijackParams HijackParams)
	{
		HijackPlayer = HijackParams.Player;
		OnHijackStartPrepareDiveEvent.Broadcast(HijackParams);
	}

	void StartHijack(FSwarmDroneHijackParams HijackParams)
	{
		HijackPlayer = HijackParams.Player;
		OnHijackStartEvent.Broadcast(HijackParams);
	}

	void StopHijack()
	{
		if (HijackPlayer != nullptr)
		{
			OnHijackStopEvent.Broadcast();
			HijackPlayer = nullptr;
		}
	}

	// Used for launching bots towards hijackable
	FSwarmDroneHijackTargetRectangle MakeBotDiveTargetRectangle() const
	{
		FSwarmDroneHijackTargetRectangle TargetRectangle;
		TargetRectangle.PlaneNormal = ForwardVector;
		TargetRectangle.WorldOrigin = WorldLocation;
		TargetRectangle.Size = DiveAreaSize;

		return TargetRectangle;
	}

	FTransform GetTargetCameraTransform() const
	{
		return FTransform(FQuat::MakeFromX(-ForwardVector), WorldLocation + ForwardVector * HijackSettings.CameraDistanceFromPanel);
	}

	FVector GetWorldPlayerSnapLocation()
	{
		return WorldTransform.TransformPositionNoScale(PlayerSnapLocation);
	}

	UFUNCTION(BlueprintPure)
	bool IsHijacked() const
	{
		return HijackPlayer != nullptr;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetHijackPlayer() const
	{
		return HijackPlayer;
	}
}