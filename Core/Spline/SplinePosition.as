/**
 * Represents a point on a spline that can be moved back and forth along the spline.
 *
 * The point will automatically traverse spline connections and loops.
 */
struct FSplinePosition
{
	UPROPERTY()
	private UHazeSplineComponent SplineComponent;
	UPROPERTY()
	private float SplineDistance = 0.0;
	UPROPERTY()
	private bool bForwardOnSpline = true;

	FSplinePosition() {}
	FSplinePosition(UHazeSplineComponent OnSpline, float DistanceOnSpline, bool bForwardFacing)
	{
		SplineComponent = OnSpline;

		if(SplineComponent.IsClosedLoop())
			SplineDistance = Math::Wrap(DistanceOnSpline, 0, SplineComponent.SplineLength);
		else
			SplineDistance = Math::Clamp(DistanceOnSpline, 0, SplineComponent.SplineLength);

		bForwardOnSpline = bForwardFacing;
	}

	FString ToString() const
	{
		if (SplineComponent == nullptr)
			return "Invalid";
		return f"Spline {SplineComponent.Name} at {SplineDistance}, Forward: {bForwardOnSpline}";
	}

	/**
	 * Whether we hold a valid position on a spline.
	 */
	bool IsValid() const
	{
		return SplineComponent != nullptr;
	}

	/**
	 * The current spline we are on. Can change when moving across connections.
	 */
	UHazeSplineComponent GetCurrentSpline() const property
	{
		return SplineComponent;
	}

	/**
	 * Spline distance on the current spline.
	 */
	float GetCurrentSplineDistance() const property
	{
		return SplineDistance;
	}

	/**
	 * Whether we are facing forward relative to the current spline.
	 */
	bool IsForwardOnSpline() const
	{
		return bForwardOnSpline;
	}

	/**
	 * The world location of the current position on the spline.
	 */
	FVector GetWorldLocation() const property
	{
		if (SplineComponent == nullptr)
			return FVector::ZeroVector;
		return SplineComponent.GetWorldLocationAtSplineDistance(SplineDistance);
	}

	/**
	 * The world rotation of the current position on the spline.
	 */
	FQuat GetWorldRotation() const property
	{
		if (SplineComponent == nullptr)
			return FQuat::Identity;
		FQuat Rotation = SplineComponent.GetWorldRotationAtSplineDistance(SplineDistance);
		if (!bForwardOnSpline)
		{
			// Rotate around the up vector by PI radians to reverse the rotation
			Rotation = FQuat(Rotation.UpVector, PI) * Rotation;
		}
		return Rotation;
	}

	/**
	 * The up vector of the current position on the spline.
	 */
	FVector GetWorldUpVector() const property
	{
		if (SplineComponent == nullptr)
			return FVector::UpVector;
		FQuat Rotation = SplineComponent.GetWorldRotationAtSplineDistance(SplineDistance);
		return Rotation.UpVector;
	}

	/**
	 * The forward vector of the current position on the spline.
	 */
	FVector GetWorldForwardVector() const property
	{
		return GetWorldRotation().ForwardVector;
	}

	/**
	 * The right vector of the current position on the spline.
	 */
	FVector GetWorldRightVector() const property
	{
		return GetWorldRotation().RightVector;
	}

	/**
	 * The spline tangent of the current position on the spline.
	 *
	 * Note: The tangent is always the forward tangent, even if we are currently
	 * facing backwards on the spline.
	 */
	FVector GetWorldTangent() const property
	{
		if (SplineComponent == nullptr)
			return FVector::ForwardVector;
		return SplineComponent.GetWorldTangentAtSplineDistance(SplineDistance);
	}

	/**
	 * The scale of the current position on the spline.
	 */
	FVector GetWorldScale3D() const property
	{
		if (SplineComponent == nullptr)
			return FVector::OneVector;
		return SplineComponent.GetWorldScale3DAtSplineDistance(SplineDistance);
	}

	/**
	 * The relative location of the current position on the spline.
	 */
	FVector GetRelativeLocation() const property
	{
		if (SplineComponent == nullptr)
			return FVector::ZeroVector;
		return SplineComponent.GetRelativeLocationAtSplineDistance(SplineDistance);
	}

	/**
	 * The relative rotation of the current position on the spline.
	 */
	FQuat GetRelativeRotation() const property
	{
		if (SplineComponent == nullptr)
			return FQuat::Identity;
		FQuat Rotation = SplineComponent.GetRelativeRotationAtSplineDistance(SplineDistance);
		if (!bForwardOnSpline)
		{
			// Rotate around the up vector by PI radians to reverse the rotation
			Rotation = FQuat(Rotation.UpVector, PI) * Rotation;
		}
		return Rotation;
	}

	/**
	 * The relative up vector of the current position on the spline.
	 */
	FVector GetRelativeUpVector() const property
	{
		if (SplineComponent == nullptr)
			return FVector::UpVector;
		FQuat Rotation = SplineComponent.GetRelativeRotationAtSplineDistance(SplineDistance);
		return Rotation.UpVector;
	}

	/**
	 * The relative forward vector of the current position on the spline.
	 */
	FVector GetRelativeForwardVector() const property
	{
		return GetRelativeRotation().ForwardVector;
	}

	/**
	 * The relative right vector of the current position on the spline.
	 */
	FVector GetRelativeRightVector() const property
	{
		return GetRelativeRotation().RightVector;
	}

	/**
	 * The relative spline tangent of the current position on the spline.
	 *
	 * Note: The tangent is always the forward tangent, even if we are currently
	 * facing backwards on the spline.
	 */
	FVector GetRelativeTangent() const property
	{
		if (SplineComponent == nullptr)
			return FVector::ForwardVector;
		return SplineComponent.GetRelativeTangentAtSplineDistance(SplineDistance);
	}

	/**
	 * The relative scale of the current position on the spline.
	 */
	FVector GetRelativeScale3D() const property
	{
		if (SplineComponent == nullptr)
			return FVector::OneVector;
		return SplineComponent.GetWorldScale3DAtSplineDistance(SplineDistance);
	}

	/**
	 * The relative transform of the current position on the spline.
	 */
	FTransform GetRelativeTransform() const property
	{
		if (SplineComponent == nullptr)
			return FTransform::Identity;

		FTransform Transform = SplineComponent.GetRelativeTransformAtSplineDistance(SplineDistance);

		// Reverse the rotation in the transform if we're facing backwards on the spline
		if (!bForwardOnSpline)
		{
			const FVector UpVector = Transform.TransformVector(FVector::UpVector);
			const FQuat RevRot(UpVector, PI);
			Transform.SetRotation(RevRot * Transform.GetRotation());
		}
		return Transform;
	}

	/**
	 * The transform of the current position on the spline.
	 */
	FTransform GetWorldTransform() const property
	{
		if (SplineComponent == nullptr)
			return FTransform::Identity;

		FTransform Transform = SplineComponent.GetWorldTransformAtSplineDistance(SplineDistance);

		// Reverse the rotation in the transform if we're facing backwards on the spline
		if (!bForwardOnSpline)
		{
			const FVector UpVector = Transform.TransformVector(FVector::UpVector);
			const FQuat RevRot(UpVector, PI);
			Transform.SetRotation(RevRot * Transform.GetRotation());
		}
		return Transform;
	}
	
	/**
	 * The transform of the current position on the spline, without the scale.
	 */
	FTransform GetWorldTransformNoScale() const property
	{
		FTransform Transform = GetWorldTransform();
		Transform.Scale3D = FVector::OneVector;
		return Transform;
	}

	/**
	 * Change our facing on the spline to match the given rotation as closely as possible.
	 */
	void MatchFacingTo(FQuat Rotation)
	{
		if (SplineComponent == nullptr)
			return;

		FQuat SplineRotation = SplineComponent.GetWorldRotationAtSplineDistance(SplineDistance);
		float DotRotation = Rotation.ForwardVector.DotProduct(SplineRotation.ForwardVector);
		bForwardOnSpline = (DotRotation > 0.0);
	}

	/**
	 * Change our facing on the spline to match the given rotation as closely as possible.
	 */
	void MatchFacingTo(FRotator Rotation)
	{
		MatchFacingTo(Rotation.Quaternion());
	}

	/**
	 * Reverse our current facing on the spline to be in the opposite direction.
	 */
	void ReverseFacing()
	{
		bForwardOnSpline = !bForwardOnSpline;
	}

	/**
	 * Move the specified distance following the spline, obeying facing.
	 * MoveDistance can be negative to move in the opposite direction of our current facing.
	 *
	 * Returns true if the full move was possible on the spline.
	 * Returns false if the move reached the end of the spline system.
	 */
	bool Move(float MoveDistance)
	{
		float RemainingDistance = 0.0;
		return Move(MoveDistance, RemainingDistance);
	}

	/**
	 * Move the specified distance following the spline, obeying facing.
	 * MoveDistance can be negative to move in the opposite direction of our current facing.
	 *
	 * Returns true if the full move was possible on the spline.
	 * Returns false if the move reached the end of the spline system.
	 *
	 * OutRemainingDistance is set to the remaining distance we were unable to
	 * move due to reaching the end of the spline.
	 */
	bool Move(float MoveDistance, float&out OutRemainingDistance)
	{
		if (SplineComponent == nullptr)
		{
			OutRemainingDistance = MoveDistance;
			return false;
		}

		bool bMoveWasReversed = MoveDistance < 0.0;
		float RemainingMove = Math::Abs(MoveDistance);
		int StuckCount = 0;

		while (RemainingMove > 0.0 && StuckCount < 15)
		{
			bool bIsGoingForward = bMoveWasReversed ? !bForwardOnSpline : bForwardOnSpline;

			// Check if there are any connections we should traverse on our current spline
			int TraverseConnection = -1;
			float ConnectionDistance = 0.0;

			float EndDistance = SplineDistance + (bIsGoingForward ? RemainingMove : -RemainingMove);

			for(int i = 0, Count = SplineComponent.SplineConnections.Num(); i < Count; ++i)
			{
				const FSplineConnection& Connection = SplineComponent.SplineConnections[i];
				if (bIsGoingForward)
				{
					if (Connection.DistanceOnEntrySpline < SplineDistance)
						continue;
					if (Connection.DistanceOnEntrySpline > EndDistance)
						continue;
					if (!Connection.bCanEnterGoingForward)
						continue;
				}
				else
				{
					if (Connection.DistanceOnEntrySpline > SplineDistance)
						continue;
					if (Connection.DistanceOnEntrySpline < EndDistance)
						continue;
					if (!Connection.bCanEnterGoingBackward)
						continue;
				}

				if (Connection.ExitSpline == nullptr)
					continue;

				float Dist = Math::Abs(Connection.DistanceOnEntrySpline - SplineDistance);
				if (Dist < ConnectionDistance || TraverseConnection == -1)
				{
					TraverseConnection = i;
					ConnectionDistance = Dist;
				}
			}

			// Do the transition if we crossed one
			if (TraverseConnection != -1)
			{
				const FSplineConnection& Connection = SplineComponent.SplineConnections[TraverseConnection];
				RemainingMove -= ConnectionDistance;

				if (ConnectionDistance > 0.0)
				{
					StuckCount = 0;
				}
				else
				{
					StuckCount += 1;
					if (StuckCount >= 10)
						devError(f"Spline position movement got stuck in an infinite loop of spline connections on spline {SplineComponent.PathName}");
				}

				SplineComponent = Connection.ExitSpline;
				SplineDistance = Connection.DistanceOnExitSpline;
				bForwardOnSpline = (Connection.bExitForwardOnSpline != bMoveWasReversed);
				continue;
			}

			// Proceed on the same spline, we didn't transition
			float PrevSplineDistance = SplineDistance;
			if (bIsGoingForward)
				SplineDistance += RemainingMove;
			else
				SplineDistance -= RemainingMove;

			// Check if we fell off the spline with this delta
			if (SplineDistance < 0.0)
			{
				SplineDistance = 0.0;
				OutRemainingDistance = Math::Sign(MoveDistance) * (Math::Abs(MoveDistance) - Math::Abs(SplineDistance - PrevSplineDistance));
				return false;
			}

			if (SplineDistance > SplineComponent.SplineLength)
			{
				SplineDistance = SplineComponent.SplineLength;
				OutRemainingDistance = Math::Sign(MoveDistance) * (Math::Abs(MoveDistance) - Math::Abs(SplineDistance - PrevSplineDistance));
				return false;
			}

			OutRemainingDistance = 0.0;
			return true;
		}

		OutRemainingDistance = RemainingMove;
		return true;
	}

	/**
	 * Whether it is at all possible to reach the target position from our position.
	 *
	 * OBS! This will return true even if we have to move backwards to reach the target!
	 */
	bool CanReach(const FSplinePosition& Target) const
	{
		return DeltaToReachClosest(Target) != MAX_flt;
	}

	/**
	 * Whether it is at all possible to reach the target position from our position
	 * by moving with the specified polarity.
	 *
	 * Note: Positive polarity means that we only try to reach the target by
	 * passing positive distances into Move(). Negative polarity only checks
	 * negative distances.
	 */
	bool CanReach(const FSplinePosition& Target, ESplineMovementPolarity Polarity) const
	{
		return Distance(Target, Polarity) != MAX_flt;
	}

	/**
	 * Lerp from our position to the other with the specified alpha.
	 *
	 * Will always choose the closest to direction to lerp in, so might lerp backwards,
	 * as if we passed a negative number into Move().
	 * 
	 * Returns the current position unchanged if the target is not reachable.
	 */
	FSplinePosition LerpClosest(const FSplinePosition& Other, float Alpha) const
	{
		float Dist = DeltaToReachClosest(Other);
		if (Dist == MAX_flt)
			return this;

		FSplinePosition NewPosition = this;
		NewPosition.Move(Math::Clamp(Alpha, 0.0, 1.0) * Dist);
		return NewPosition;
	}

	/**
	 * Lerp from our position to the other with the specified alpha, only
	 * moving with the specified polarity.
	 *
	 * Returns the current position unchanged if the target is not reachable.
	 *
	 * Note: Positive polarity means that we only try to reach the target by
	 * passing positive distances into Move(). Negative polarity only checks
	 * negative distances.
	 */
	FSplinePosition Lerp(const FSplinePosition& Target, float Alpha, ESplineMovementPolarity Polarity)
	{
		const float Dist = Distance(Target, Polarity);
		if (Dist == MAX_flt)
		{
			return this;
		}
		else if (Dist == 0.0)
		{
			return Target;
		}

		FSplinePosition NewPosition = this;
		if (Polarity == ESplineMovementPolarity::Positive)
			NewPosition.Move(Math::Clamp(Alpha, 0.0, 1.0) * Dist);
		else
			NewPosition.Move(Math::Clamp(Alpha, 0.0, 1.0) * -Dist);
		return NewPosition;
	}

	/**
	 * Get the movement distance we would need to pass into Move() in
	 * order to reach the target point, going in either direction.
	 *
	 * OBS! This will return a negative delta if we need to Move() with a
	 * negative move distance in order to reach the target point!
	 *
	 * Returns MAX_flt if the target is not connected to us at all.
	 */
	float DeltaToReachClosest(const FSplinePosition& Target) const
	{
		float FwdDist = Distance(Target, ESplineMovementPolarity::Positive);
		float BackDist = Distance(Target, ESplineMovementPolarity::Negative);

		if (BackDist < FwdDist)
			return -BackDist;
		else
			return FwdDist;
	}

	/**
	 * Get the distance to the target spline position, only moving with the specified polarity.
	 *
	 * Returns MAX_flt if the target is not connected to us in this direction.
	 *
	 * Note: Positive polarity means that we only try to reach the target by
	 * passing positive distances into Move(). Negative polarity only checks
	 * negative distances.
	 */
	float Distance(const FSplinePosition& Target, ESplineMovementPolarity Polarity) const
	{
		if (SplineComponent == nullptr)
			return MAX_flt;
		if (!Target.IsValid())
			return MAX_flt;

		if (CurrentSpline == Target.CurrentSpline
			&& Math::IsNearlyEqual(SplineDistance, Target.SplineDistance))
		{
			return 0.0;
		}

		TArray<FSplineRange> VisitSplines;

		bool bPositivePolarity = (Polarity == ESplineMovementPolarity::Positive);

		FSplineRange StartRange;
		StartRange.Spline = SplineComponent;
		StartRange.StartPosition = SplineDistance;
		StartRange.bForward = bForwardOnSpline;

		VisitSplines.Add(StartRange);

		int VisitIndex = 0;
		float TotalDistance = 0.0;

		while (VisitIndex < VisitSplines.Num())
		{
			FSplineRange& Range = VisitSplines[VisitIndex];

			bool bMovingForwardInRange = (Range.bForward == bPositivePolarity);

			// Calculate where this range will end, either with the next connection or the spline end
			int TraverseConnection = -1;
			float ConnectionDistance = 0.0;

			for(int i = 0, Count = Range.Spline.SplineConnections.Num(); i < Count; ++i)
			{
				const FSplineConnection& Connection = Range.Spline.SplineConnections[i];
				if (bMovingForwardInRange)
				{
					if (Connection.DistanceOnEntrySpline < Range.StartPosition)
						continue;
					if (!Connection.bCanEnterGoingForward)
						continue;
				}
				else
				{
					if (Connection.DistanceOnEntrySpline > Range.StartPosition)
						continue;
					if (!Connection.bCanEnterGoingBackward)
						continue;
				}

				if (Connection.ExitSpline == nullptr)
					continue;

				float Dist = Math::Abs(Connection.DistanceOnEntrySpline - Range.StartPosition);
				if (Dist < ConnectionDistance || TraverseConnection == -1)
				{
					TraverseConnection = i;
					ConnectionDistance = Dist;
				}
			}

			if (TraverseConnection == -1)
				Range.EndPosition = !bMovingForwardInRange ? 0.0 : Range.Spline.SplineLength;
			else
				Range.EndPosition = Range.Spline.SplineConnections[TraverseConnection].DistanceOnEntrySpline;

			// Check if this range includes the target position
			if (Range.Spline == Target.CurrentSpline)
			{
				if (Range.Contains(Target.SplineComponent, Target.SplineDistance))
				{
					TotalDistance += Math::Abs(Range.StartPosition - Target.SplineDistance);
					return TotalDistance;
				}
			}

			// Visit the next range we're going to as well
			if (TraverseConnection != -1)
			{
				const FSplineConnection& Connection = Range.Spline.SplineConnections[TraverseConnection];

				FSplineRange NextRange;
				NextRange.Spline = Connection.ExitSpline;
				NextRange.StartPosition = Connection.DistanceOnExitSpline;
				NextRange.bForward = Connection.bExitForwardOnSpline == bPositivePolarity;

				TotalDistance += Math::Abs(Range.EndPosition - Range.StartPosition);

				// If we've already visited this spot before, don't visit it again
				bool bAlreadyVisited = false;
				for (const FSplineRange& CheckRange : VisitSplines)
				{
					if (CheckRange.bForward != NextRange.bForward)
						continue;
					if (CheckRange.Contains(NextRange.Spline, NextRange.StartPosition))
					{
						bAlreadyVisited = true;
						break;
					}
				}

				if (!bAlreadyVisited)
					VisitSplines.Add(NextRange);
			}

			++VisitIndex;
		}

		return MAX_flt;
	}

	/**
	 * Check whether this spline position is reachable between the two specified spline positions.
	 */
	bool IsBetweenPositions(FSplinePosition A, FSplinePosition B) const
	{
		return IsBetweenPositionsWithPolarity(A, B, ESplineMovementPolarity::Positive)
			|| IsBetweenPositionsWithPolarity(A, B, ESplineMovementPolarity::Negative);
	}

	/**
	 * Check whether this spline position is reachable between the two specified spline positions.
	 * Only checks moving between A and B with the specified polarity.
	 *
	 * Note: Positive polarity means that we only try to reach the target by
	 * passing positive distances into Move(). Negative polarity only checks
	 * negative distances.
	 */
	bool IsBetweenPositionsWithPolarity(FSplinePosition A, FSplinePosition B, ESplineMovementPolarity Polarity) const
	{
		if (!IsValid())
			return false;
		if (!A.IsValid())
			return false;
		if (!B.IsValid())
			return false;

		TArray<FSplineRange> VisitSplines;

		bool bPositivePolarity = (Polarity == ESplineMovementPolarity::Positive);

		FSplineRange StartRange;
		StartRange.Spline = A.CurrentSpline;
		StartRange.StartPosition = A.SplineDistance;
		StartRange.bForward = A.bForwardOnSpline;

		VisitSplines.Add(StartRange);

		int VisitIndex = 0;
		float TotalDistance = 0.0;

		while (VisitIndex < VisitSplines.Num())
		{
			FSplineRange& Range = VisitSplines[VisitIndex];

			bool bMovingForwardInRange = (Range.bForward == bPositivePolarity);

			// Calculate where this range will end, either with the next connection or the spline end
			int TraverseConnection = -1;
			float ConnectionDistance = 0.0;

			for(int i = 0, Count = Range.Spline.SplineConnections.Num(); i < Count; ++i)
			{
				const FSplineConnection& Connection = Range.Spline.SplineConnections[i];
				if (bMovingForwardInRange)
				{
					if (Connection.DistanceOnEntrySpline < Range.StartPosition)
						continue;
					if (!Connection.bCanEnterGoingForward)
						continue;
				}
				else
				{
					if (Connection.DistanceOnEntrySpline > Range.StartPosition)
						continue;
					if (!Connection.bCanEnterGoingBackward)
						continue;
				}

				if (Connection.ExitSpline == nullptr)
					continue;

				float Dist = Math::Abs(Connection.DistanceOnEntrySpline - Range.StartPosition);
				if (Dist < ConnectionDistance || TraverseConnection == -1)
				{
					TraverseConnection = i;
					ConnectionDistance = Dist;
				}
			}

			if (TraverseConnection == -1)
				Range.EndPosition = !bMovingForwardInRange ? 0.0 : Range.Spline.SplineLength;
			else
				Range.EndPosition = Range.Spline.SplineConnections[TraverseConnection].DistanceOnEntrySpline;

			// If the range contains the B position we end it there
			if (Range.Contains(B))
			{
				// The shortened range might still contain our target point
				Range.EndPosition = B.CurrentSplineDistance;
				return Range.Contains(this);
			}

			// If the range contains our target point then it is between A and B
			if (Range.Contains(this))
				return true;

			// Visit the next range we're going to as well
			if (TraverseConnection != -1)
			{
				const FSplineConnection& Connection = Range.Spline.SplineConnections[TraverseConnection];

				FSplineRange NextRange;
				NextRange.Spline = Connection.ExitSpline;
				NextRange.StartPosition = Connection.DistanceOnExitSpline;
				NextRange.bForward = Connection.bExitForwardOnSpline == bPositivePolarity;

				TotalDistance += Math::Abs(Range.EndPosition - Range.StartPosition);

				// If we've already visited this spot before, don't visit it again
				bool bAlreadyVisited = false;
				for (const FSplineRange& CheckRange : VisitSplines)
				{
					if (CheckRange.bForward != NextRange.bForward)
						continue;
					if (CheckRange.Contains(NextRange.Spline, NextRange.StartPosition))
					{
						bAlreadyVisited = true;
						break;
					}
				}

				if (!bAlreadyVisited)
					VisitSplines.Add(NextRange);
			}

			++VisitIndex;
		}

		return false;
	}

	/**
	 * Are we at the start of the current spline?
	 * NOTE: This does not take connections into account!
	 */
	bool IsAtStart() const
	{
		return SplineDistance < KINDA_SMALL_NUMBER;
	}

	/**
	 * Are we at the end of the current spline?
	 * NOTE: This does not take connections into account!
	 */
	bool IsAtEnd() const
	{
		return SplineDistance > SplineComponent.SplineLength - KINDA_SMALL_NUMBER;
	}

	/**
	 * Are we at the either the start or the end of the current spline?
	 * NOTE: This does not take connections into account!
	 */
	bool IsAtStartOrEnd() const
	{
		return IsAtStart() || IsAtEnd();
	}
};

enum ESplineMovementPolarity
{
	Positive,
	Negative,
};

struct FSplineRange
{
	UHazeSplineComponent Spline = nullptr;
	float StartPosition = 0.0;
	float EndPosition = 0.0;
	bool bForward = true;

	bool Contains(FSplinePosition Position) const
	{
		return Contains(Position.CurrentSpline, Position.CurrentSplineDistance);
	}

	bool Contains(UHazeSplineComponent InSpline, float InPosition) const
	{
		if (Spline != InSpline)
			return false;
		if (StartPosition < EndPosition)
		{
			if (InPosition < StartPosition)
				return false;
			if (InPosition > EndPosition)
				return false;
		}
		else
		{
			if (InPosition > StartPosition)
				return false;
			if (InPosition < EndPosition)
				return false;
		}
		return true;
	}
};