
namespace Targetable
{

// Increase or decrease the score depending on the distance from the player
void ApplyDistanceToScore(FTargetableQuery& Query)
{
	if (!Query.bDistanceAppliedToScore)
	{
		Query.Result.Score /= (Math::Max(Query.DistanceToTargetable, 1.0) / 1000.0);
		Query.bDistanceAppliedToScore = true;
	}
}

// Apply the distance to the player and only allow targeting within a specific range
void ApplyTargetableRange(FTargetableQuery& Query, float TargetableRange)
{
	// Make sure closer points have higher score
	ApplyDistanceToScore(Query);

	if (Query.DistanceToTargetable > TargetableRange)
	{
		// Cannot be targeted from this distance
		Query.Result.bPossibleTarget = false;
	}
}

/**
 * Apply the distance to the player and only allow targeting within a specific range
 * If this targetable is already the current primary target, we extend the targetable range slightly,
 * this makes it less likely that we show a primary target and then immediately lose it as the user tries to press it.
 */
void ApplyTargetableRangeWithBuffer(FTargetableQuery& Query, float TargetableRange, float AdditionalBufferRange)
{
	// Make sure closer points have higher score
	ApplyDistanceToScore(Query);

	if (Query.bWasPreviousPrimary)
	{
		if (Query.DistanceToTargetable > TargetableRange + AdditionalBufferRange)
		{
			// Cannot be targeted from this distance
			Query.Result.bPossibleTarget = false;
		}
	}
	else
	{
		if (Query.DistanceToTargetable > TargetableRange)
		{
			// Cannot be targeted from this distance
			Query.Result.bPossibleTarget = false;
		}
	}
}

// Apply the distance to the player and only show the targetable at all within a specific range
void ApplyVisibleRange(FTargetableQuery& Query, float VisibleRange)
{
	// Make sure closer points have higher score
	ApplyDistanceToScore(Query);

	Query.bHasHandledVisibility = true;
	if (Query.DistanceToTargetable > VisibleRange)
	{
		// Targetable is not visible from this distance
		Query.Result.bVisible = false;
		Query.Result.bPossibleTarget = false;
	}
}

// Mark that visibility is handled manually instead of using ApplyVisibleRange
void MarkVisibilityHandled(FTargetableQuery& Query)
{
	Query.bHasHandledVisibility = true;
}

/**
 * Apply scoring to the query relative to how much the player is looking at this targetable.
 * This scoring also takes distance to the player into account among various other things,
 * and is optimized to feel natural for interaction-style targetables.
 * 
 * If you want always to target only the targetable closest to the center of the screen,
 * use Targetable::ScoreLookAtAim() instead.
 * 
 * Note: When the player is in side-scrolling or top-down mode, this will automatically
 * call Score2DTargeting() instead!
 */
void ScoreCameraTargetingInteraction(FTargetableQuery& Query, float MaxDistance = 1000.0)
{
	const float DistanceMax = 100.0;
	const float CameraMax = 100.0;
	const float TargetedBonusScore = 5.0;

	// If our score is already 0, we don't need to do any extra targeting calculations
	if (Query.Result.Score <= 0.0)
		return;
	if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
		return;

	// If we're in 2d-targeting mode, score with that instead
	if (Query.Is2DTargeting())
	{
		Score2DInteractionTargeting(Query);
		return;
	}

	const FVector WorldUp = UHazeMovementComponent::Get(Query.Player).GetWorldUp();
	const float MaxScore = DistanceMax + CameraMax + TargetedBonusScore;
	if (MaxScore <= 0)
	{
		Query.Result.Score = 0.0;
		Query.Result.bPossibleTarget = false;
		return;
	}

	float DistanceAlpha = Math::Clamp(Query.DistanceToTargetable / MaxDistance, 0.0, 1.0);
	float DistanceScore = (1.0 - DistanceAlpha) * DistanceMax;

	FVector CameraDirection = Query.Player.ViewRotation.ForwardVector;
	
	const FVector SearchDirection = CameraDirection.ConstrainToPlane(WorldUp).GetSafeNormal();
	const FVector PointOrigin = Query.TargetableLocation;
	const FVector PlayerOrigin = Query.Player.GetActorCenterLocation();

	const FVector DirToPoint = (PointOrigin - PlayerOrigin).GetSafeNormal();
	const float DotValue = DirToPoint.DotProduct(SearchDirection);
	
	// Skip distance score behind that is more behind the player
	if (DotValue <= -0.5)
		DistanceScore = 0.0;

	// We check if the object is closer to the camera then the player
	const FVector CameraLocation = Query.Player.ViewLocation;
	const float DistanceToPlayerSq = PlayerOrigin.DistSquared(PointOrigin);
	const float DistanceToCameraSq = CameraLocation.DistSquared(PointOrigin);
	if (DistanceToCameraSq * 1.2 < DistanceToPlayerSq)
		DistanceScore = 0.0;

	// Objects that are more focused beneath us are more valid
	const FVector CameraDirectionToTarget = (PointOrigin - CameraLocation).GetSafeNormal();

	FRotator CameraRotation = CameraDirection.Rotation();
	CameraRotation.Pitch += 10.0; 
	CameraDirection = CameraRotation.GetForwardVector();

	const float CameraDot = Math::Max(CameraDirection.DotProduct(CameraDirectionToTarget), 0.0);

	const float CameraAlpha = Math::Pow(Math::SinusoidalIn(0.0, 1.0, CameraDot), 3.0);

	// Set the camera score
	float CameraScore = CameraAlpha * CameraMax;

	// Apply Bonus Scores
	float BonusScore = 0;
	if (Query.bWasPreviousPrimary)
		BonusScore += TargetedBonusScore;

	// Calculate the alpha
	const float TotalScore = DistanceScore + CameraScore + BonusScore;

	// Reverse the distance scoring we've already applied, so we aren't applying it twice
	if (Query.bDistanceAppliedToScore)
		Query.Result.Score *= (Math::Max(Query.DistanceToTargetable, 1.0) / 1000.0);

	Query.Result.Score *= TotalScore / MaxScore;

	// Mark distance scoring as applied so we don't apply it again
	Query.bDistanceAppliedToScore = true;
}

/**
 * Score targetables purely by how close they are to the center of the screen.
 * This creates more of an 'aiming' effect.
 * 
 * Since this scores ignoring distance to the player, make sure to set a maximum range with
 * Targetable::ApplyVisibleRange() or Targetable::ApplyTargetableRange().
 * 
 * Note: When the player is in side-scrolling or top-down mode, this will automatically
 * call Score2DTargeting() instead!
 * 
 * Note: This secretly actually _does_ use the distance, but only for points that are near each other on screen.
 * That way, when a close point and a farther point are behind each other it will choose the closer point.
 */
void ScoreLookAtAim(FTargetableQuery& Query, bool bInvalidIfOffScreen = true, bool bInvalidIfBehindPlayer = true)
{
	// If we're already invisible, we don't need to do any extra targeting calculations
	if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
		return;
	if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
		return;

	// If we're in 2d-targeting mode, score with that instead
	if (Query.Is2DTargeting())
	{
		Score2DTargeting(Query);
		return;
	}

	// Make sure the target is actually on screen at all
	FVector TargetLocation = Query.TargetableLocation;
	FVector2D ScreenPosition;
	bool bInFrontOfScreen = SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, TargetLocation, ScreenPosition);
	if (!bInFrontOfScreen)
	{
		Query.Result.Score = 0.0;
		Query.Result.bPossibleTarget = false;
		Query.Result.bVisible = false;
		return;
	}

	if (bInvalidIfBehindPlayer)
	{
		// Depending on targeting mode, If the targetable is between the player and the camera we ignore it entirely or vice versa
		FVector ViewDirection = Query.ViewForwardVector;
		FVector DirectionFromPlayer = (TargetLocation - Query.PlayerLocation).GetSafeNormal();
		const bool bBetweenCameraAndPlayer = ViewDirection.DotProduct(DirectionFromPlayer) < 0.0;

		if ((Query.TargetingMode != EPlayerTargetingMode::MovingTowardsCamera && bBetweenCameraAndPlayer)
			|| (Query.TargetingMode == EPlayerTargetingMode::MovingTowardsCamera && !bBetweenCameraAndPlayer))
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return;
		}
	}

	if (bInvalidIfOffScreen && (ScreenPosition.X < 0.0 || ScreenPosition.X > 1.0 || ScreenPosition.Y < 0.0 || ScreenPosition.Y > 1.0))
	{
		Query.Result.Score = 0.0;
		Query.Result.bPossibleTarget = false;
		return;
	}

	const FVector2D ScreenCenter(0.5, 0.5);
	float ScreenDistance = ScreenPosition.Distance(ScreenCenter);

	// Use FilterScore to filter targets so only targets closest to the aim are used
	Query.Result.FilterScore = 100.0 - ScreenDistance;
	Query.Result.FilterScoreThreshold = 0.04;

	// Our normal score is still distance based, the filter score deals with the aim angle
	Targetable::ApplyDistanceToScore(Query);
}

bool IsOnScreen(FTargetableQuery& Query)
{
	FVector TargetLocation = Query.TargetableLocation;
	FVector2D ScreenPosition;
	bool bInFrontOfScreen = SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, TargetLocation, ScreenPosition);
	if (!bInFrontOfScreen)
	{
		return false;
	}

	if ((ScreenPosition.X < 0.0 || ScreenPosition.X > 1.0 || ScreenPosition.Y < 0.0 || ScreenPosition.Y > 1.0))
	{
		return false;
	}

	return true;
}

/**
 * Score targetables by how much the player is wanting to move in the direction of the targetable.
 * 
 * Since this scores mostly ignoring distance to the player, make sure to set a maximum range with
 * Targetable::ApplyVisibleRange() or Targetable::ApplyTargetableRange().
 */
void ScoreWantedMovementInput(FTargetableQuery& Query, float MaximumHorizontalAngle = 360.0, float MaximumVerticalAngle = 360.0, bool bAllowWithZeroInput = false, bool bUseNonLockedMovementInput = false)
{
	// If we're already invisible, we don't need to do any extra targeting calculations
	if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
		return;
	if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
		return;

	FVector InputVector = Query.PlayerMovementInput;
	if (bUseNonLockedMovementInput)
		InputVector = Query.PlayerNonLockedMovementInput;

	if (InputVector.IsNearlyZero())
	{
		if (!bAllowWithZeroInput)
		{
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return;
		}
		else
		{
			// If this is allowed with zero input, use either the player velocity or facing
			InputVector = Query.Player.GetActorHorizontalVelocity();
			if (InputVector.IsNearlyZero())
				InputVector = Query.PlayerFacingInputDirection;
		}
	}

	FVector Delta = (Query.TargetableLocation - Query.Player.ActorLocation);
	FVector HorizDirection = Delta.ConstrainToPlane(Query.PlayerWorldUp).GetSafeNormal();
	float InputAngle = HorizDirection.GetAngleDegreesTo(InputVector);
	if (Math::Abs(InputAngle) > MaximumHorizontalAngle)
	{
		Query.Result.bPossibleTarget = false;
		Query.Result.bVisible = false;
		return;
	}

	float VerticalAngle = Delta.GetSafeNormal().GetAngleDegreesTo(Query.PlayerWorldUp);
	if (!Math::IsWithin(VerticalAngle, 90.0 - MaximumVerticalAngle, 90.0 + MaximumVerticalAngle))
	{
		Query.Result.bPossibleTarget = false;
		Query.Result.bVisible = false;
		return;
	}

	// Use filter score so the input angle is the most important measure, and we only use camera and distance for similar input angles
	Query.Result.FilterScore = 360.0 - InputAngle;
	Query.Result.FilterScoreThreshold = 6.0;
	Query.Result.Score /= Math::Max(InputAngle, 0.01);

	// Make sure the target is actually on screen at all
	FVector TargetLocation = Query.TargetableLocation;
	FVector2D ScreenPosition;
	bool bInFrontOfScreen = SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, TargetLocation, ScreenPosition);
	if (!bInFrontOfScreen)
	{
		// Behind the screen has low score, but is still allowed if our input is backwards
		Query.Result.Score /= 2.0;
	}
	else
	{
		const FVector2D ScreenCenter(0.5, 0.5);
		float ScreenDistance = ScreenPosition.Distance(ScreenCenter);
		Query.Result.Score /= Math::Max(ScreenDistance, 0.01);
	}

	// Our normal score is still distance based, the filter score deals with the aim angle
	Targetable::ApplyDistanceToScore(Query);
}

/**
 * Score targetables based on a 2D plane between the player and the camera, combined with the facing direction.
 * This is used mainly automatically, in top-down and side-scrolling targeting modes.
 */
void Score2DTargeting(FTargetableQuery& Query)
{
	// If our score is already 0, we don't need to do any extra targeting calculations
	if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
		return;
	if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
		return;

	// Always apply distance first, our facing calculation goes on top of that
	ApplyDistanceToScore(Query);

	// Make a plane perpendicular to the camera at the player's position
	FVector PlayerPosition = Query.Player.ActorLocation;
	FVector PlaneNormal = -Query.ViewForwardVector;

	// Project the player's current facing onto that plane
	FVector InputDirection = Query.PlayerTargetingInput.GetSafeNormal();
	if (InputDirection.IsNearlyZero())
		InputDirection = Query.PlayerFacingInputDirection;

	FVector FacingOnPlane = InputDirection.ConstrainToPlane(PlaneNormal);

	// If the player is facing perpendicular to the plane, then we don't have information so we should just use distance scoring
	if (FacingOnPlane.IsNearlyZero())
		return;

	FVector TargetDelta = Query.TargetableLocation - PlayerPosition;

	// Anything that is 'behind' the player should be ignored
	float FacingDot = FacingOnPlane.DotProduct(TargetDelta);
	if (FacingDot < 0.0)
	{
		Query.Result.Score = 0.0;
		Query.Result.bVisible = false;
		Query.Result.bPossibleTarget = false;
		return;
	}

	// In top-down mode, we score based on the angle from the player's forward as well.
	// We apply this in _addition_ to the distance scoring, so closer points are still preferred.
	// In sidescroller we can only face left or right, so we *don't* apply this, or it would be hard to go up or down.
	if (Query.TargetingMode == EPlayerTargetingMode::TopDown)
	{
		// Relative weight of the facing angle compared to distance
		const float SCORE_WEIGHT_FACING = 3.0;

		float DeltaSize = TargetDelta.Size();
		if (DeltaSize > 0.0)
		{
			float Angle = Math::Acos(FacingDot / DeltaSize);
			if (Angle > 0.0)
			{
				float Multiplier = Math::Pow(1.0 - (Angle / PI), SCORE_WEIGHT_FACING);
				Query.Result.Score *= Multiplier;
			}
		}
	}
}

/**
 * Same as Score2DTargeting except it does not discard based on facing direction.
 * This is to be able to interact with things that are behind you.
 */
void Score2DInteractionTargeting(FTargetableQuery& Query)
{
	// If our score is already 0, we don't need to do any extra targeting calculations
	if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
		return;
	if (!Query.Result.bVisible && !Query.Result.bPossibleTarget)
		return;

	// Always apply distance first, our facing calculation goes on top of that
	ApplyDistanceToScore(Query);

	// Make a plane perpendicular to the camera at the player's position
	FVector PlayerPosition = Query.Player.ActorLocation;
	FVector PlaneNormal = -Query.ViewForwardVector;

	// Project the player's current facing onto that plane
	FVector InputDirection = Query.PlayerTargetingInput.GetSafeNormal();
	if (InputDirection.IsNearlyZero())
		InputDirection = Query.Player.ActorForwardVector;

	FVector FacingOnPlane = InputDirection.ConstrainToPlane(PlaneNormal);

	// If the player is facing perpendicular to the plane, then we don't have information so we should just use distance scoring
	if (FacingOnPlane.IsNearlyZero())
		return;

	FVector TargetDelta = Query.TargetableLocation - PlayerPosition;

	// Anything that is 'behind' the player should be ignored
	float FacingDot = FacingOnPlane.DotProduct(TargetDelta);

	// In top-down mode, we score based on the angle from the player's forward as well.
	// We apply this in _addition_ to the distance scoring, so closer points are still preferred.
	// In sidescroller we can only face left or right, so we *don't* apply this, or it would be hard to go up or down.
	if (Query.TargetingMode == EPlayerTargetingMode::TopDown)
	{
		// Relative weight of the facing angle compared to distance
		const float SCORE_WEIGHT_FACING = 3.0;

		float DeltaSize = TargetDelta.Size();
		if (DeltaSize > 0.0)
		{
			float Angle = Math::Acos(FacingDot / DeltaSize);
			if (Angle > 0.0)
			{
				float Multiplier = Math::Pow(1.0 - (Angle / PI), SCORE_WEIGHT_FACING);
				Query.Result.Score *= Multiplier;
			}
		}
	}
}

/**
 * Do a trace to make sure the targetable isn't behind something from the perspective
 * of the player's current camera.
 */
bool RequireNotOccludedFromCamera(FTargetableQuery& Query, float TracePullback = 20.0, bool bIgnoreOwnerCollision = true)
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

	FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"TargetableOcclusion");
	Trace.UseLine();
	Trace.IgnorePlayers();
	Trace.IgnoreCameraHiddenComponents(Query.Player);

	if (bIgnoreOwnerCollision)
		Trace.IgnoreActor(Query.Component.Owner);

	FVector TargetPosition = Query.TargetableLocation;
	if (TracePullback != 0.0)
		 TargetPosition -= (TargetPosition - Query.ViewLocation).GetSafeNormal() * TracePullback;

	if(Query.ViewLocation.Equals(TargetPosition))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(
		Query.ViewLocation,
		TargetPosition,
	);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireNotOccludedFromCamera", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Do a trace to make sure the targetable isn't behind something from the perspective
 * of the player's current aim ray.
 */
bool RequireAimNotOccluded(FTargetableQuery& Query, float TracePullback = 20.0)
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

	FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"TargetableOcclusion");;
	Trace.UseLine();
	Trace.IgnorePlayers();
	Trace.IgnoreCameraHiddenComponents(Query.Player);
	Trace.IgnoreActor(Query.Component.Owner);

	FVector TargetPosition = Query.TargetableLocation;
	if (TracePullback != 0.0)
		 TargetPosition -= (TargetPosition - Query.AimRay.Origin).GetSafeNormal() * TracePullback;

	if(Query.AimRay.Origin.Equals(TargetPosition))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(
		Query.AimRay.Origin,
		TargetPosition,
	);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireAimNotOccluded", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Do a trace to make sure the targetable isn't behind something from the perspective
 * of the player's current aim ray.
 */
bool RequireAimToPointNotOccluded(FTargetableQuery& Query, FVector TargetPoint, const TArray<UPrimitiveComponent>& IgnoredComponents, float TracePullback = 20.0, bool bIgnoreOwnerCollision = true)
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

	FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"TargetableOcclusion");;
	Trace.UseLine();
	Trace.IgnorePlayers();
	Trace.IgnoreCameraHiddenComponents(Query.Player);

	if (bIgnoreOwnerCollision)
		Trace.IgnoreActor(Query.Component.Owner);

	if (IgnoredComponents.Num() > 0)
		Trace.IgnoreComponents(IgnoredComponents);

	FVector TargetPosition = TargetPoint;
	if (TracePullback != 0.0)
		 TargetPosition -= (TargetPosition - Query.AimRay.Origin).GetSafeNormal() * TracePullback;

	if(Query.AimRay.Origin.Equals(TargetPosition))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(
		Query.AimRay.Origin,
		TargetPosition,
	);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireAimToPointNotOccluded", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Generic sweep to check if something is obstructing two points.
 * Ignores player.
 * If Radius <= 0, we use a line.
 */
bool RequireSweepUnblocked(FTargetableQuery& Query, FVector Start, FVector End, float Radius = -1, bool bIgnoreOwner = true, bool bIgnoreAttachParent = false, float KeepDistanceAmount = 0)
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

	FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming, n"TargetableOcclusion");;

	if(Radius < KINDA_SMALL_NUMBER)
		Trace.UseLine();
	else
		Trace.UseSphereShape(Radius);

	if(bIgnoreOwner)
		Trace.IgnoreActor(Query.Component.Owner);
	
	if(bIgnoreAttachParent && Query.Component.Owner.AttachParentActor != nullptr)
		Trace.IgnoreActor(Query.Component.Owner.AttachParentActor);

	FVector StartLocation = Start;
	FVector EndLocation = End;

	FVector Direction = (EndLocation - StartLocation).GetSafeNormal();

	// Pull back from the target a bit so we don't hit stuff behind the target
	EndLocation -= (Direction * (Query.Player.CapsuleComponent.CapsuleRadius + KeepDistanceAmount));

	if(StartLocation.Equals(EndLocation))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(StartLocation, EndLocation);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireSweepUnblocked", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Do a trace to make sure the player is able to freely reach the target point without
 * being blocked by anything.
 */
bool RequirePlayerCanReachUnblocked(FTargetableQuery& Query, bool bIgnoreOwner = true, bool bIgnoreAttachParent = false, float KeepDistanceAmount = 0)
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

	FHazeTraceSettings Trace = Trace::InitFromPlayer(
		Query.Player,
		n"TargetableCanReach",
	);

	if(bIgnoreOwner)
		Trace.IgnoreActor(Query.Component.Owner);
	
	if(bIgnoreAttachParent && Query.Component.Owner.AttachParentActor != nullptr)
		Trace.IgnoreActor(Query.Component.Owner.AttachParentActor);

	FVector StartLocation = Query.Player.ActorLocation;
	FVector EndLocation = Query.TargetableLocation;

	float Distance = StartLocation.Distance(EndLocation);
	FVector Direction = (EndLocation - StartLocation).GetSafeNormal();

	if (Distance < Query.Player.CapsuleComponent.CapsuleRadius + KeepDistanceAmount)
		return true;

	// Pull back from the target a bit so we don't hit stuff behind the target
	EndLocation -= (Direction * (Query.Player.CapsuleComponent.CapsuleRadius + KeepDistanceAmount));

	if(StartLocation.Equals(EndLocation))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(StartLocation, EndLocation);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequirePlayerCanReachUnblocked", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Do a line trace from the center of the player to the target and check if there are any obstructions.
 * Does the same as RequirePlayerCanReach but with a single line trace.
 */
bool RequireUnobstructedLineFromPlayer(FTargetableQuery& Query, bool bIgnoreOwner = true, bool bIgnoreAttachParent = false, float KeepDistanceAmount = 0)
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

	FHazeTraceSettings Trace;
	Trace.TraceWithPlayerProfile(Query.Player);
	Trace.UseLine();

	if(bIgnoreOwner)
		Trace.IgnoreActor(Query.Component.Owner);
	
	if(bIgnoreAttachParent && Query.Component.Owner.AttachParentActor != nullptr)
		Trace.IgnoreActor(Query.Component.Owner.AttachParentActor);

	FVector StartLocation = Query.Player.ActorCenterLocation;
	FVector EndLocation = Query.TargetableLocation;

	float Distance = StartLocation.Distance(EndLocation);
	FVector Direction = (EndLocation - StartLocation).GetSafeNormal();

	if (Distance < KeepDistanceAmount)
		return true;

	// Pull back from the target a bit so we don't hit stuff behind the target
	EndLocation -= (Direction * KeepDistanceAmount);

	if(StartLocation.Equals(EndLocation))
		return true;

	FHitResult Hit = Trace.QueryTraceSingle(StartLocation, EndLocation);

	#if EDITOR
	Query.DebugTraces.Add(FTargetableQueryTraceDebug("RequireUnobstructedLineFromPlayer", Hit, Trace.Shape, Trace.ShapeWorldOffset));
	#endif

	if (Hit.bBlockingHit)
	{
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

/**
 * Only allow this targetable if a player capability tag isn't blocked.
 */
bool RequireCapabilityTagNotBlocked(FTargetableQuery& Query, FName CapabilityTag)
{
	// If we are already invisible and cannot be the primary target, we don't need to check the capability tag
	if (!Query.Result.bVisible)
	{
		if (Query.Result.Score <= 0.0 || !Query.IsCurrentScoreViableForPrimary())
			return false;
		if (!Query.Result.bPossibleTarget)
			return false;
	}

	if (Query.Player.IsCapabilityTagBlocked(CapabilityTag))
	{
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

/**
 * Update the VisualProgress with a percentage, calculated from your current distance, visible and targetables ranges
 */
void ApplyVisualProgressFromRange(FTargetableQuery& Query, float VisibleRange, float TargetableRange, float BufferRange = 0.0)
{
	if (VisibleRange == TargetableRange)
		return;

	float TargetableVisualRange = TargetableRange;
	if (Query.bWasPreviousPrimary)
		TargetableVisualRange += BufferRange;

	Query.Result.VisualProgress *= Math::Clamp((VisibleRange - Query.DistanceToTargetable) / (VisibleRange - TargetableVisualRange), 0.0, 1.0);
}

};