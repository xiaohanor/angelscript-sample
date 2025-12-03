
UCLASS(NotBlueprintable)
class UMagnetDroneAutoAimComponent : UAutoAimTargetComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	default TargetableCategory = MagnetDroneTags::MagnetDroneTarget;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default AutoAimMaxAngle = 5.0;
	default MinimumDistance = 0;
	default MaximumDistance = MagnetDrone::MaxTargetableDistance_Aim;
	default TargetShape.Type = EHazeShapeType::Box;
	default TargetShape.BoxExtents = FVector(1.0, 100.0, 100.0);
	default bOnlyValidIfAimOriginIsWithinAngle = true;

	UPROPERTY(EditAnywhere, Category = "Auto Aim Zone")
	bool bInfiniteVerticalRange = false;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Auto Aim Zone|Auto Extents", Meta = (EditCondition = "TargetShape.Type == EHazeShapeType::Box", EditConditionHides))
	protected bool bCalculateAutoExtents = false;

	UPROPERTY(EditInstanceOnly, Category = "Auto Aim Zone|Auto Extents", Meta = (EditCondition = "TargetShape.Type == EHazeShapeType::Box && bCalculateAutoExtents", EditConditionHides))
	float AutoExtentsMargin = 10;

	UPROPERTY(EditInstanceOnly, Category = "Auto Aim Zone|Auto Extents", Meta = (EditCondition = "TargetShape.Type == EHazeShapeType::Box && bCalculateAutoExtents", EditConditionHides))
	float ForwardOffsetMultiplier = 1;
#endif

	UPROPERTY(EditAnywhere, Category = "Auto Aim Zone|Add Constraint", Meta = (EditCondition = "TargetShape.Type == EHazeShapeType::Box"))
	bool bAddConstrainToWithin = false;

	UPROPERTY(EditAnywhere, Category = "Auto Aim Zone|Add Constraint", Meta = (EditCondition = "TargetShape.Type == EHazeShapeType::Box && bAddConstrainToWithin"))
	float ZoneMargin = 10;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(TargetShape.Type  == EHazeShapeType::Box && bCalculateAutoExtents)
		{
			AutoScaleToBounds();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(TargetShape.Type == EHazeShapeType::Box)
		{
			if(bAddConstrainToWithin)
			{
				auto Zone = UDroneMagneticZoneComponent::Create(Owner);
				Zone.Initialize(EMagnetDroneZoneType::ConstrainToWithin, FVector2D(TargetShape.BoxExtents.Y + ZoneMargin, TargetShape.BoxExtents.Z + ZoneMargin));
				Zone.SetWorldTransform(WorldTransform);
			}
		}

#if EDITOR
		if(DevToggleMagnetDrone::DrawShapes.IsEnabled())
			SetComponentTickEnabled(true);

		DevToggleMagnetDrone::DrawShapes.BindOnChanged(this, n"OnDrawShapesChanged");
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DevToggleMagnetDrone::DrawShapes.IsEnabled())
			DebugDraw();
	}
#endif

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Bail if this target is disabled
		if (!bIsAutoAimEnabled)
			return false;

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
			PrintToScreen(f"Debugging {this}");
#endif

		switch(Query.TargetingMode)
		{
			case EPlayerTargetingMode::ThirdPerson:
			{
				return ThirdPersonTargeting(Query);
			}

			case EPlayerTargetingMode::SideScroller:
			case EPlayerTargetingMode::TopDown:
			{
				return TopDownTargeting(Query);
			}
			
			case EPlayerTargetingMode::MovingTowardsCamera:
				break;
		}

		check(false);
		return false;
	}

	protected bool TopDownTargeting(FTargetableQuery& Query) const
	{
		float Padding = 0;
		if(TargetShape.Type == EHazeShapeType::Box)
			Padding = TargetShape.BoxExtents.Size();
		else if(TargetShape.Type == EHazeShapeType::Sphere)
			Padding = TargetShape.SphereRadius;

		Query.DistanceToTargetable = DistanceFromPoint(Query.PlayerLocation);

		Targetable::ApplyVisibleRange(Query, MagnetDrone::VisibleDistance_2D + Padding);
		
		Targetable::ApplyTargetableRange(Query, MaximumDistance + Padding);

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.PlayerLocation - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		if (Query.IsCurrentScoreViableForPrimary())
		{
			FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);
			if(!RequireMagnetDroneCanReachUnblocked(Query, TargetLocation, bIgnoreActorCollisionForAimTrace))
				return false;
		}

		return true;
	}

	protected bool ThirdPersonTargeting(FTargetableQuery& Query) const
	{
		float Padding = 0;
		if(TargetShape.Type == EHazeShapeType::Box)
			Padding = TargetShape.BoxExtents.Size();
		else if(TargetShape.Type == EHazeShapeType::Sphere)
			Padding = TargetShape.SphereRadius;
			
		const FVector ClosestPoint = GetClosestPointTo(Query.PlayerLocation);
		const FVector ToClosestPoint = ClosestPoint - Query.PlayerLocation;

		if(MagnetDrone::NextGenAiming::bAimOmniDirectional)
		{
			Query.DistanceToTargetable = ToClosestPoint.Size();
		}
		else
		{
			if(bInfiniteVerticalRange)
				Query.DistanceToTargetable = FVector(ToClosestPoint.X, ToClosestPoint.Y, 0).Size();
			else
				Query.DistanceToTargetable = ToClosestPoint.Size();
		}

		Targetable::ApplyVisibleRange(Query, MaximumDistance + Padding);

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToPlayer = Query.PlayerLocation - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToPlayer);
			if(Angle > MaxAimAngle)
				return false;
		}

		// Check if we are actually inside the auto-aim arc
		FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);

		Query.DistanceToTargetable = TargetLocation.Distance(Query.AimRay.Origin);

		// Auto aim angle can change based on distance
		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);

#if !RELEASE
		// Show debugging for auto-aim if we want to
		//ShowDebug(Query.Player, MaxAngle, Query.ComputedDistance);
#endif

		FVector TargetDirection = (TargetLocation - Query.AimRay.Origin).GetSafeNormal();
		float AngularBend = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistanceForNormals(TargetDirection));

		if(MagnetDrone::NextGenAiming::bIgnoreAutoAimAngle)
		{
			MaxAngle = 90;
		}
		else
		{
			if (AngularBend > MaxAngle)
			{
				Query.Result.Score = 0.0;
				return false;
			}
		}

		if(MagnetDrone::NextGenAiming::bOnlyValidIfOnScreen)
		{
			FVector2D ViewportLocation;
			if(!SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, TargetLocation, ViewportLocation))
				return false;

			if(ViewportLocation.X < 0 || ViewportLocation.X > 1)
				return false;

			if(ViewportLocation.Y < 0 || ViewportLocation.Y > 1)
				return false;
		}

		// Score the distance based on how much we have to bend the aim
		Query.Result.Score = (1.0 - (AngularBend / MaxAngle));
		Query.Result.Score /= Math::Pow(Math::Max(Query.DistanceToTargetable, 0.01) / 1000.0, 0.1);

		// Apply bonus to score
		Query.Result.Score *= ScoreMultiplier;


		// Make sure that the new target location is not too far away
		float BaseDistanceSQ = TargetLocation.Distance(Query.PlayerLocation);

		Targetable::ApplyVisualProgressFromRange(Query, MaximumDistance + MagnetDrone::VisibleDistanceExtra_Aim, MaximumDistance);
		
		if (BaseDistanceSQ > MaximumDistance)
		{
			Query.Result.Score = 0;
			return false;
		}

		// If the point is occluded we can't target it,
		// we only do this test if we would otherwise become primary target (performance)
		if (Query.IsCurrentScoreViableForPrimary())
		{
			if(!IsDirectPathToTargetBlocked(Query))
			{
				Query.Result.Score = 0;
				return false;
			}
			if(MagnetDrone::bPrioritizeClearFromPlayerToPotentialTarget)
			{
				FTargetableQuery TempQuery = Query;
				if(!Targetable::RequireSweepUnblocked(TempQuery, Query.PlayerLocation, TargetLocation, -1, true))
				{
					Query.Result.Score = 0.001;
				}
			}

			CheckPrimaryOcclusion(Query, TargetLocation);
		}

		if(MagnetDrone::bDeprioritizePreviousAttachment)
		{
			auto AttachedComp = UMagnetDroneAttachedComponent::Get(Query.Player);
			if(AttachedComp.PreviousAttachment.IsValid() && Time::GetGameTimeSince(AttachedComp.GetDetachTime()) < MagnetDrone::DetachDeprioritizeDuration && AttachedComp.PreviousAttachment.GetAttachComp().Owner == Owner)
			{
				// Massively deprioritize us if we were what the player recently detached from
				Query.Result.Score = 0.001;
			}
		}

		return true;
	}

	bool IsDirectPathToTargetBlocked(FTargetableQuery& Query) const
	{
		// If we are already invisible and cannot be the primary target, we don't need to trace
		if (!Query.Result.bVisible)
		{
			if (Query.Result.Score <= 0.0 || !Query.IsCurrentScoreViableForPrimary())
				return false;
			if (!Query.Result.bPossibleTarget)
				return false;
		}

		Query.bHasPerformedTrace = true;

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Query.Player, n"IsDirectPathToTargetBlocked");
		Trace.TraceWithChannel(ECollisionChannel::PlayerAbilityZoe);

		FVector StartLocation = Query.PlayerLocation;
		FVector EndLocation = WorldLocation;

		if(StartLocation.Equals(EndLocation))
			return true;

		auto AttachComp = UMagnetDroneAttachedComponent::Get(Query.Player);
		if(AttachComp.IsAttached())
		{
			if(AttachComp.IsAttachedToSocket())
				Trace.IgnoreActor(AttachComp.AttachedData.GetSocketComp().Owner);
			else if(AttachComp.IsAttachedToSurface())
				Trace.IgnoreActor(AttachComp.AttachedData.GetSurfaceComp().Owner);
		}

		FHitResult Hit = Trace.QueryTraceSingle(StartLocation, EndLocation);

#if !RELEASE
		Query.DebugTraces.Add(FTargetableQueryTraceDebug("IsDirectPathToTargetBlocked", Hit, Trace.Shape, Trace.ShapeWorldOffset));
#endif

		if (Hit.bBlockingHit)
		{
			if(Hit.Actor == Owner)
				return true;
			
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return false;
		}
		else
		{
			return true;
		}
	}

	float DistanceFromPoint(FVector Point, bool bProjectToPlane = false) const
	{
		FVector RelativePoint = Point;

		if(bProjectToPlane)
			RelativePoint = Point.PointPlaneProject(WorldTransform.GetLocation(), WorldTransform.GetRotation().GetForwardVector());

		RelativePoint = WorldTransform.InverseTransformPositionNoScale(RelativePoint);

		switch(TargetShape.Type)
		{
			case EHazeShapeType::Box:
			{
				const float XDist = Math::Max(Math::Abs(RelativePoint.X) - TargetShape.BoxExtents.X, 0.0);
				const float YDist = Math::Max(Math::Abs(RelativePoint.Y) - TargetShape.BoxExtents.Y, 0.0);
				const float ZDist = Math::Max(Math::Abs(RelativePoint.Z) - TargetShape.BoxExtents.Z, 0.0);

				return XDist + YDist + ZDist;
			}

			case EHazeShapeType::Sphere:
			{
				return Math::Max(RelativePoint.Size() - TargetShape.SphereRadius, 0);
			}

			case EHazeShapeType::None:
			{
				return RelativePoint.Size();
			}

			case EHazeShapeType::Capsule:
				break;
		}

		check(false);
		return -1.0;
	}

	FVector GetClosestPointTo(const FVector& Point) const
	{

		switch(TargetShape.Type)
		{
			case EHazeShapeType::Box:
			{
				// Transform to AABB space
				const FVector RelativePoint = WorldTransform.InverseTransformPositionNoScale(Point);

				// Project each axis onto a side of the cube
				const FVector RelativeProjectedPoint = FVector(
					Math::Min(Math::Abs(RelativePoint.X), TargetShape.BoxExtents.X) * Math::Sign(RelativePoint.X),
					Math::Min(Math::Abs(RelativePoint.Y), TargetShape.BoxExtents.Y) * Math::Sign(RelativePoint.Y),
					Math::Min(Math::Abs(RelativePoint.Z), TargetShape.BoxExtents.Z) * Math::Sign(RelativePoint.Z)
				);

				// Transform back to world space
				return WorldTransform.TransformPositionNoScale(RelativeProjectedPoint);
			}

			case EHazeShapeType::None:
			{
				return WorldLocation;
			}

			case EHazeShapeType::Sphere:
			{
				FVector DirectionToPoint = (Point - WorldLocation).GetSafeNormal();
				return WorldLocation + DirectionToPoint * TargetShape.SphereRadius;
			}

			case EHazeShapeType::Capsule:
				break;
		}

		check(false);
		return FVector::ZeroVector;
	}

	FVector GetAutoAimTargetPointForRay(FAimingRay Ray, bool bConstrainToPlane = true) const override
	{
		FVector TargetLocation;

		// If we have a shape, bend to the edge of the shape
		if (!TargetShape.IsZeroSize())
		{
			if(UMagnetDroneSettings::GetSettings(Drone::GetMagnetDronePlayer()).bUse2DTargeting)
			{
				TargetLocation = Drone::GetMagnetDronePlayer().ActorLocation;
			}
			else
			{
				// First find the closest location to the aim ray
				TargetLocation = TargetShape.GetClosestPointToLine(
					GetWorldTransform(),
					Ray.Origin, Ray.Direction
				);
			}

			// Then get the closest location on the shape to that location
			TargetLocation = GetClosestPointTo(TargetLocation);
		}
		else
		{
			TargetLocation = GetWorldLocation();
		}

		// If we have a 2D constraint, project it to that plane
		if (Ray.HasConstraintPlane())
			TargetLocation = TargetLocation.PointPlaneProject(Ray.Origin, Ray.ConstraintPlaneNormal);

		return TargetLocation;
	}

	bool RequireMagnetDroneCanReachUnblocked(FTargetableQuery& Query, FVector TargetLocation, bool bIgnoreOwner = true, bool bIgnoreAttachParent = false, float KeepDistanceAmount = 0) const
	{
		// If our score is already 0, we don't need to do any extra traces
		if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
			return false;
		if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
			return false;

		if(Query.Player.IsPlayerDead())
			return false;

		Query.bHasPerformedTrace = true;

		FHazeTraceSettings Trace = Trace::InitFromPlayer(
			Query.Player,
			n"TargetableCanReach",
		);

		if(bIgnoreAttachParent && Query.Component.Owner.AttachParentActor != nullptr)
			Trace.IgnoreActor(Query.Component.Owner.AttachParentActor);

		FVector StartLocation = Query.Player.ActorLocation;
		FVector EndLocation = TargetLocation;

		//FVector Direction = (EndLocation - StartLocation).GetSafeNormal();

		// Pull back from the target a bit so we don't hit stuff behind the target
		//EndLocation -= (Direction * (MagnetDrone::Radius + KeepDistanceAmount));

		if(StartLocation.Equals(EndLocation))
			return true;

		FHitResult Hit = Trace.QueryTraceSingle(StartLocation, EndLocation);

		#if EDITOR
		Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireMagnetDroneCanReachUnblocked", Hit, Trace.Shape, Trace.ShapeWorldOffset));
		#endif

		if (Hit.IsValidBlockingHit())
		{
			if(Hit.Actor == Query.Component.Owner)
			{
				return true;
			}
			
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return false;
		}
		else
		{
			return true;
		}
	}

#if EDITOR
	UFUNCTION()
	private void OnDrawShapesChanged(bool bNewState)
	{
		SetComponentTickEnabled(bNewState);
	}

	protected void DebugDraw()
	{
		if (TargetShape.IsZeroSize())
			return;

		switch (TargetShape.Type)
		{
			case EHazeShapeType::Box:
				Debug::DrawDebugBox(
					WorldLocation,
					TargetShape.BoxExtents,
					ComponentQuat.Rotator(),
					FLinearColor::Green
				);
			break;
			case EHazeShapeType::Sphere:
				Debug::DrawDebugSphere(
					WorldLocation,
					TargetShape.SphereRadius,
					12,
					FLinearColor::Green,
				);
			break;

			default:
				break;
		}
	}

	private void AutoScaleToBounds()
	{
		AutoExtentsMargin = Math::Max(AutoExtentsMargin, 0);
		FBox ActorBounds = Owner.GetActorLocalBoundingBox(true);
		FVector Extents = ActorBounds.Extent * Owner.ActorScale3D;
		FVector Origin = Owner.ActorTransform.TransformPosition(ActorBounds.Center);
		AutoExtentsMargin = Math::Min(AutoExtentsMargin, Math::Min(Extents.Y, Extents.Z));

		const FVector Offset = Owner.ActorForwardVector * (Extents.X * ForwardOffsetMultiplier);

		SetWorldLocation(Origin + Offset);
		SetWorldRotation(Owner.ActorQuat);

		TargetShape.BoxExtents.X = 1;
		TargetShape.BoxExtents.Y = Extents.Y - AutoExtentsMargin;
		TargetShape.BoxExtents.Z = Extents.Z - AutoExtentsMargin;
	}
#endif
};

#if EDITOR
class UMagnetDroneAutoAimComponentVisualizer : UAutoAimTargetVisualizer
{
	default VisualizedClass = UMagnetDroneAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);
		
		auto AutoAim = Cast<UMagnetDroneAutoAimComponent>(Component);
		if(AutoAim == nullptr)
			return;

		if(AutoAim.TargetShape.Type == EHazeShapeType::Box)
		{
			if(AutoAim.bAddConstrainToWithin)
			{
				FVector Extents = AutoAim.TargetShape.BoxExtents;
				Extents.Y -= AutoAim.ZoneMargin;
				Extents.Z -= AutoAim.ZoneMargin;
				DrawWireBox(AutoAim.WorldLocation, Extents, AutoAim.ComponentQuat, MagnetDrone::GetZoneColor(EMagnetDroneZoneType::ConstrainToWithin), 3.0);		
			}
		}
	}
};
#endif