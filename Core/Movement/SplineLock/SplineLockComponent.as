/**
 * Manages the current state during SplineLock
 */
class USplineLockComponent : UActorComponent
{
	access Internal = protected, LockMovementToSplineComponent, LockPlayerMovementToSplineComponent, UnlockMovementFromSpline, UnlockPlayerMovementFromSpline;
	access Resolver = protected, USplineLockResolverExtension(inherited);

	TSubclassOf<USplineLockResolverExtension> ResolverExtensionClass = USplineLockResolverExtension;

	protected AHazeActor HazeOwner;
	protected UHazeMovementComponent MoveComp;
	protected UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;

	TInstigated<FPlayerSplineLockSettings> InstigatedSettings;

	access:Resolver
	EPlayerSplineLockStatus SplineLockStatus = EPlayerSplineLockStatus::Unset;

	access:Resolver
	EPlayerSplineLockPlaneType PlaneLockType = EPlayerSplineLockPlaneType::Horizontal;

	uint LastConstraintFrame = 0;
	float LastConstraintDeviation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		if(!ensure(HazeOwner != nullptr, f"A Spline Lock component can only be added to a AHazeActor! {Owner}"))
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwner);
		if(!ensure(MoveComp != nullptr, f"A Spline Lock component requires a Movement component to function, but none were found on {Owner}!"))
			return;

		if(!ensure(MoveComp.SplineLockComponent == nullptr, f"A Spline Lock component has already been added to MoveComp on {Owner}!"))
			return;

		MoveComp.SplineLockComponent = this;
		SyncedActorPositionComp = UHazeCrumbSyncedActorPositionComponent::Get(HazeOwner);
	}

	const FVector& GetWorldUp() const
	{
		return MoveComp.WorldUp;
	}

	UHazeOffsetComponent GetMeshOffsetComponent() const
	{
		return UHazeOffsetComponent::Get(HazeOwner);
	}

	access:Internal 
	void LockOnSplineInternal(const FPlayerSplineLockSettings Settings)
	{
		PlaneLockType = Settings.LockSettings.LockType;
	
		// Snap the current player location to the spline plane, and use that as WantedLocation
		const FVector WantedLocation = HazeOwner.ActorLocation.PointPlaneProject(
			GetSplinePosition().WorldLocation,
			SplineLock::GetDeviationRight(PlaneLockType, GetSplinePosition(),
			GetWorldUp()));

		if(Settings.EnterSettings == nullptr || Settings.EnterSettings.EnterType == EPlayerSplineLockEnterType::MoveInto)
		{
			SplineLockStatus = EPlayerSplineLockStatus::Entering;
		}
		else if(Settings.EnterSettings.EnterType == EPlayerSplineLockEnterType::Snap)
		{
			FVector GroundPosition = SnapToStartingLocation(WantedLocation);
			HazeOwner.TeleportActor(GroundPosition, GetSplinePosition().WorldRotation.Rotator(), this);
			SplineLockStatus = EPlayerSplineLockStatus::Locked;
		}
		else if(Settings.EnterSettings.EnterType == EPlayerSplineLockEnterType::SmoothLerp)
		{
			UHazeOffsetComponent MeshOffsetComponent = GetMeshOffsetComponent();
			if(MeshOffsetComponent != nullptr)
				MeshOffsetComponent.FreezeTransformAndLerpBackToParent(this, Settings.EnterSettings.EnterSmoothLerpDuration);
			
			FVector GroundPosition = SnapToStartingLocation(WantedLocation);
			HazeOwner.SetActorLocation(GroundPosition);
			SplineLockStatus = EPlayerSplineLockStatus::Locked;
		}
		else if(Settings.EnterSettings.EnterType == EPlayerSplineLockEnterType::SnapAtTheBeginningOfMovement)
		{		
			SplineLockStatus = EPlayerSplineLockStatus::Locked;
		}

		if(Settings.LockSettings.bConstrainInitialVelocityAlongSpline)
		{
			FVector ConstrainedVelocity = HazeOwner.ActorVelocity.VectorPlaneProject(SplineLock::GetDeviationRight(PlaneLockType, GetSplinePosition(), GetWorldUp()));
			HazeOwner.SetActorVelocity(ConstrainedVelocity);
		}

		SyncLocation(GetSplinePosition());
	}

	void ClearSplineLockOnInternal()
	{
		SplineLockStatus = EPlayerSplineLockStatus::Unset;
		SyncedActorPositionComp.ClearRelativePositionSync(this);
	}

	private FVector SnapToStartingLocation(FVector WantedLocation) const
	{
		if(HasActiveSplineLock())
			return HazeOwner.ActorLocation;

		FHazeTraceSettings GroundTraceSettings = Trace::InitFromMovementComponent(MoveComp);

		FVector TraceStart;
		FVector TraceEnd;

		if(MoveComp.CollisionShape.IsCapsule())
		{
			float CapsuleRadius = MoveComp.CollisionShape.Shape.CapsuleRadius;
			float CapsuleHalfHeight = MoveComp.CollisionShape.Shape.CapsuleHalfHeight;
			
			// Start the sweep with a sphere from the top of the player capsule
			// Using a sphere prevents penetrating when the bottom of the player capsule is in the floor
			GroundTraceSettings.UseSphereShape(CapsuleRadius);

			const float DistanceToCapCenter = CapsuleHalfHeight - CapsuleRadius;

			// Start trace in the center of the top cap
			TraceStart = WantedLocation + (GetWorldUp() * DistanceToCapCenter);
			
			// Trace the distance to the center of the bottom cap
			float TraceLength = DistanceToCapCenter * 2;

			if(MoveComp.IsOnAnyGround())
			{
				// If we were previously on the ground, add additional offset for how far vertically we are moved by the snap
				const float StartHeightOffset = Math::Abs((WantedLocation - Owner.ActorLocation).DotProduct(GetWorldUp()));
				TraceLength += StartHeightOffset;
			}
			
			// End trace in the center of the bottom cap
			TraceEnd = TraceStart - (GetWorldUp() * TraceLength);
		}
		else
		{
			const float Offset = MoveComp.CollisionShape.Extent.Z;
			float TraceLength = Offset * 2;

			if(MoveComp.IsOnAnyGround())
			{
				// If we were previously on the ground, add additional offset for how far vertically we are moved by the snap
				const float StartHeightOffset = Math::Abs((WantedLocation - Owner.ActorLocation).DotProduct(GetWorldUp()));
				TraceLength += StartHeightOffset;
			}

			TraceStart = MoveComp.ShapeComponent.WorldLocation + GetWorldUp() * Offset;
			TraceEnd = TraceStart - (GetWorldUp() * Offset);
		}

		const int Attempts = 3;
		for(int i = 0; i < Attempts; i++)
		{
			FHitResult GroundHit = GroundTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
			FTemporalLog TemporalLog = MoveComp.GetTemporalLog().Page("Spline Lock").Section("SnapToStartingLocation");
			TemporalLog.HitResults(f"GroundTrace [{i+1}/{Attempts}]", GroundHit, GroundTraceSettings.Shape, GroundTraceSettings.ShapeWorldOffset);
#endif

			if(GroundHit.bBlockingHit)
			{
				if(GroundHit.bStartPenetrating)
				{
					// Try again
					GroundTraceSettings.IgnoreComponent(GroundHit.Component);
					continue;
				}
				else
				{
					FMovementHitResult ValidHit(GroundHit,  MoveComp.GetGroundedSafetyMargin());
					ValidHit.ApplyPullback();
					return ValidHit.Location;
				}
			}
			else
			{
				return WantedLocation;
			}
		}

		devError(f"Could not find ground for {Owner} spline lock. Move the spline closer to the ground or don't snap the enter.");
		return WantedLocation;
	}

	void SyncLocation(FSplinePosition Location)
	{
		if (InstigatedSettings.Get().LockSettings.bSyncPositionCrumbsRelativeToSpline)
			SyncedActorPositionComp.ApplySplineRelativePositionSync(this, Location, EInstigatePriority::Low);
		else
			SyncedActorPositionComp.ClearRelativePositionSync(this);
	}

	bool IsSplineLockActiveWithInstigator(FInstigator Instigator) const
	{
		if (GetCurrentSpline() != nullptr && SplineLockStatus != EPlayerSplineLockStatus::Unset)
		{
			if (InstigatedSettings.CurrentInstigator == Instigator)
				return true;
		}

		return false;
	}

	bool IsEnteringSpline() const
	{
		return SplineLockStatus == EPlayerSplineLockStatus::Entering;
	}

	bool IsUsingRubberBanding() const
	{
		return GetCurrentSettings().RubberBandSettings != nullptr;
	}

	bool HasActiveSplineLock() const
	{
		return GetCurrentSpline() != nullptr && SplineLockStatus != EPlayerSplineLockStatus::Unset;
	}

	bool AppliedSplineLockConstraintThisFrame() const
	{
		if(!HasActiveSplineLock())
			return false;

		return LastConstraintFrame == Time::FrameNumber;
	}

	bool AppliedSplineLockConstraintThisOrLastFrame() const
	{
		if(!HasActiveSplineLock())
			return false;

		return LastConstraintFrame >= Time::FrameNumber - 1;
	}

	UHazeSplineComponent GetCurrentSpline() const property
	{
		return GetCurrentSettings().Spline;
	}

	FSplinePosition GetSplinePosition() const
	{
		// Since the spline might be create in a way that is not aligning with the ground we are walking on
		// we need to find the location that is closest to the location we are on.
		// but if we build a spiral spline, the closest horizontal position might not actually be the closest
		// position, so we need to check both. 
		auto SplinePosition = GetCurrentSpline().GetClosestSplinePositionToWorldLocation(HazeOwner.ActorLocation);
		if(PlaneLockType == EPlayerSplineLockPlaneType::Horizontal)
		{
			FVector UpVector = SplineLock::GetUpVector(PlaneLockType, SplinePosition, GetWorldUp());
			SplinePosition = SplineLock::GetClosestSplineHorizontalLocation(GetCurrentSpline(), HazeOwner.ActorLocation, UpVector, MoveComp.CollisionShape.Shape.CapsuleRadius * 2);
		}

		return SplinePosition;
	}

	const FPlayerSplineLockSettings& GetCurrentSettings() const
	{
		return InstigatedSettings.Get();
	}

	/**
	 * We finalize the spline lock movement by applying all the resolved information back into the spline lock component
	 * If we have reached close enough to the deviation while entering, we now lock the movement unto the spline
	 */
	void ApplySplineLock(FSplinePosition CurrentSplinePosition, FVector CurrentLocation, FVector WorldUp)
	{
		if(HasControl())
		{
			SyncLocation(CurrentSplinePosition);	
		}
	}

	FVector GetLockedMovementInput(FVector OriginalInput) const
	{
		const FPlayerSplineLockSettings Settings = GetCurrentSettings();

		// Don't do anything without input, or if we have disabled input redirection
		if(OriginalInput.IsNearlyZero() || !Settings.LockSettings.bRedirectMovementInput)
			return OriginalInput;

		if(Settings.Spline == nullptr)
			return OriginalInput;

		if(CurrentSpline == nullptr)
			return OriginalInput;

		switch(PlaneLockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
				return GetLockedMovementInputHorizontal(OriginalInput);

			case EPlayerSplineLockPlaneType::SplinePlane:
			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
				return GetLockedMovementInputSplinePlane(OriginalInput);
		}
	}

	protected FVector GetLockedMovementInputHorizontal(FVector OriginalInput) const
	{
		const FPlayerSplineLockSettings& Settings = GetCurrentSettings();

		float MoveIntoSmoothnessDistance = 0;
		if(Settings.EnterSettings != nullptr && IsEnteringSpline())
			MoveIntoSmoothnessDistance = Settings.EnterSettings.MoveIntoSmoothnessDistance;

		const FVector WorldUp = GetWorldUp();
		const FVector OriginalInputDir = OriginalInput.GetSafeNormal();
		const float OriginalInputSize = OriginalInput.Size();
		
		const FVector SplineForward = SplineLock::GetMovementForward(PlaneLockType, GetSplinePosition(), WorldUp);

		const float SplineDot = OriginalInputDir.DotProduct(SplineForward);

		// Remap so that 0.6 in the spline direction is 1
		const float SplineInputSize = Math::GetMappedRangeValueClamped(
			FVector2D(0, 0.6),
			FVector2D(0, 1),
			Math::Abs(SplineDot * OriginalInputSize)
		);

		// A little bit of dead zone
		if(SplineInputSize < 0.1)
			return FVector::ZeroVector;

		const float SplineInputDir = SplineInputSize > 0 ? Math::Sign(SplineDot) : 1;

		if(SplineLockStatus == EPlayerSplineLockStatus::Locked)
		{
			return SplineForward * SplineInputDir * SplineInputSize;
		}
		else
		{	
			float InputOffset = Math::Max(MoveComp.CollisionShape.Shape.CapsuleRadius, MoveIntoSmoothnessDistance);

			// If we can leave at the end, we check that here.
			if(SplineLockStatus == EPlayerSplineLockStatus::Leaving)
			{
				FSplinePosition EndOfSpline = GetSplinePosition();
				if(!EndOfSpline.Move(SplineInputDir))
				{		
					if(Settings.LockSettings.bCanLeaveSplineAtEnd)
						return OriginalInput;
					else
						return FVector::ZeroVector;
				}
			}

			FSplinePosition UpcomingPosition = GetSplinePosition();

			const FVector ActorLocation = HazeOwner.ActorLocation;

			FVector PlayerLocationOnPlane = ActorLocation.PointPlaneProject(UpcomingPosition.WorldLocation, UpcomingPosition.WorldRightVector);
			FVector WorldLocationToReach;

			float HorizOffset = (PlayerLocationOnPlane - UpcomingPosition.WorldLocation).DotProduct(SplineForward);
			if (!Math::IsNearlyZero(HorizOffset, KINDA_SMALL_NUMBER))
			{
				// The spline is somewhere away from us right now, so move to the plane of the spline point instead
				if (Math::Abs(HorizOffset) > InputOffset || Math::Sign(HorizOffset) != SplineInputDir)
				{
					WorldLocationToReach = PlayerLocationOnPlane + UpcomingPosition.WorldForwardVector * (SplineInputDir * InputOffset);
				}
				else
				{
					UpcomingPosition.Move(SplineInputDir * (InputOffset - Math::Abs(HorizOffset)));
					WorldLocationToReach = UpcomingPosition.WorldLocation;
				}
			}
			else
			{
				UpcomingPosition.Move(SplineInputDir * InputOffset);
				WorldLocationToReach = UpcomingPosition.WorldLocation;
			}

			const FVector DirToLocation = (WorldLocationToReach - ActorLocation).VectorPlaneProject(WorldUp).GetSafeNormal();
			if(SplineInputSize > 0.1)
				return DirToLocation * OriginalInputSize;	
			else
				return DirToLocation * SplineInputSize * OriginalInputSize;
		}
	}

	protected FVector GetLockedMovementInputSplinePlane(FVector OriginalInput) const
	{
		return OriginalInput.VectorPlaneProject(GetSplinePosition().WorldRightVector);
	}
};