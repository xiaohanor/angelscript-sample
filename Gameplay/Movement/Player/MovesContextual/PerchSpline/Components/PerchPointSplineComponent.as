class UPerchPointSplineComponent : UPerchPointComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PrePhysics;
	default PrimaryComponentTick.EndTickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(EditAnywhere)
	bool bGrappleToStaticSplineDistance = false;

	UPROPERTY(EditAnywhere)
	float GrappleStaticSplineDistance = 0.0;

	private bool bCanEvaluate = false;

	void SetEvaluationEnabled(bool bEnabled)
	{
		bCanEvaluate = bEnabled;
		SetComponentTickEnabled(bEnabled);
		for (auto Player : Game::Players)
			SetTargetableConsidered(Player, bEnabled);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!bCanEvaluate)
			return false;

		// If this is a jumpto query, use the jumpto location instead of the grapple location
		if (Query.QueryCategory == n"Jump")
		{
			Query.TargetableLocation = GetJumpToTargetTransform(Query.Player).Location;
			Query.DistanceToTargetable = Query.TargetableLocation.Distance(Query.PlayerLocation);
		}

		return Super::CheckTargetable(Query);
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);
	}

	FVector CalculateWidgetVisualOffset(AHazePlayerCharacter Player, UTargetableWidget Widget) const override
	{
		if (bGrappleToStaticSplineDistance && IsValid(ConnectedSpline))
			return ConnectedSpline.Spline.GetRelativeLocationAtSplineDistance(GrappleStaticSplineDistance);
		else
			return Super::CalculateWidgetVisualOffset(Player, Widget);
	}

	USceneComponent GetWidgetAttachComponent(AHazePlayerCharacter Player, UTargetableWidget Widget) override
	{
		if (bGrappleToStaticSplineDistance && IsValid(ConnectedSpline))
			return ConnectedSpline.Spline;
		else
			return this;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Don't move while we're interacting with the perch point
		if (!bMovePoint || IsPlayerJumpingToPoint[0] || IsPlayerJumpingToPoint[1] || IsPlayerLandingOnPoint[0] || IsPlayerLandingOnPoint[1])
			return;
		if (!bCanEvaluate)
			return;
		if (IsDisabled())
			return;

		AHazePlayerCharacter Player;
		if (UsableByPlayers == EHazeSelectPlayer::Mio)
			Player = Game::Mio;
		else
			Player = Game::Zoe;

		if (bIsPlayerGrapplingToPoint[Player])
			return;

		if (bAllowGrappleToPoint && !bGrappleToStaticSplineDistance)
		{
			// Take the player's view rotation into account for finding which point to grapple to
			FVector ViewForward = Player.ViewRotation.ForwardVector;
			ViewForward = ViewForward.ConstrainToPlane(Player.MovementWorldUp);

			float VisibleRange = ActivationRange + AdditionalVisibleRange;

			FVector LineStart = Player.ActorLocation;
			FVector LineEnd = LineStart + ViewForward * VisibleRange;

			FSplinePosition SplinePos = ConnectedSpline.Spline.GetClosestSplinePositionToLineSegment(LineStart, LineEnd);

			FVector WidgetLocation = WorldTransform.TransformPosition(WidgetVisualOffset);
			WidgetLocation = Math::VInterpTo(
				WidgetLocation,
				SplinePos.WorldLocation,
				DeltaTime,
				4.0
			);

			WorldLocation = SplinePos.WorldLocation;
			WidgetVisualOffset = WorldTransform.InverseTransformPosition(WidgetLocation);

			//Debug::DrawDebugSphere(SplinePos.WorldLocation, 10.0, LineColor = GetColorForPlayer(Player.Player));
		}
		else
		{
			// Just take the closest point to the spline
			WorldTransform = GetGrappleToTransform(Player);
		}
	}

	void SnapToWorldLocation (FVector Location)
	{
		WorldLocation = Location;
	}

	FTransform GetGrappleToTransform(AHazePlayerCharacter Player) const
	{
		if (bGrappleToStaticSplineDistance)
		{
			FTransform PointTransform = ConnectedSpline.Spline.GetWorldTransformAtSplineDistance(GrappleStaticSplineDistance);
			PointTransform.SetScale3D(FVector::OneVector);
			return PointTransform;
		}
		else
		{
			FTransform PointTransform = ConnectedSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(
				Player.ActorLocation
			);
			PointTransform.SetScale3D(FVector::OneVector);
			return PointTransform;
		}
	}

	FTransform GetVerticalLandOnTransform(AHazePlayerCharacter Player) const override
	{
		// If this isn't a grapple point this is already calculated by tick
		if (!bAllowGrappleToPoint)
			return WorldTransform;

		FTransform PointTransform = ConnectedSpline.Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(
			Player.ActorLocation, Player.MovementWorldUp
		).WorldTransform;
		PointTransform.SetScale3D(FVector::OneVector);
		return PointTransform;
	}

	FTransform GetJumpToTargetTransform(AHazePlayerCharacter Player) const override
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);

		// Instead of placing the point nearest to the player, we place it nearest to
		// the line that the player wants to move in.
		// In case this is a standard "land", this won't change anything (it's still 
		// going to find the location closest to the player since that's where the line starts)
		// In case we're doing a "jump to", however, this will allow the stick input to
		// determine where on the spline to land, which is much nicer than always transfering
		// to the closest point to the player.
		FVector LineStart = Player.ActorLocation;
		FVector LineEnd = LineStart + MoveComp.NonLockedMovementInput * ConnectedSpline.ActivationRange;

		//FSplinePosition SplinePos = PerchSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FSplinePosition SplinePos = ConnectedSpline.Spline.GetClosestSplinePositionToLineSegment(LineStart, LineEnd);

		FTransform PointTransform = SplinePos.WorldTransform;
		PointTransform.SetScale3D(FVector::OneVector);

		//Debug::DrawDebugSphere(PointTransform.Location, 50.0, LineColor = GetColorForPlayer(Player.Player));

		return PointTransform;
	}

	FTransform GetHorizontalLandOnTransform(AHazePlayerCharacter Player) const override
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);

		// Instead of placing the point nearest to the player, we place it nearest to
		// the line that the player wants to move in.
		// In case this is a standard "land", this won't change anything (it's still 
		// going to find the location closest to the player since that's where the line starts)
		// In case we're doing a "jump to", however, this will allow the stick input to
		// determine where on the spline to land, which is much nicer than always transfering
		// to the closest point to the player.
		FVector LineStart = Player.ActorLocation;
		FVector LineEnd = LineStart + MoveComp.NonLockedMovementInput * 500.0;

		//FSplinePosition SplinePos = PerchSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FSplinePosition SplinePos = ConnectedSpline.Spline.GetPlaneConstrainedClosestSplinePositionToLineSegment(LineStart, LineEnd, MoveComp.WorldUp);

		FTransform PointTransform = SplinePos.WorldTransform;
		PointTransform.SetScale3D(FVector::OneVector);

		// Debug::DrawDebugSphere(PointTransform.Location, 50.0, LineColor = GetColorForPlayer(Player.Player));

		return PointTransform;
	}

	FVector GetLocationForVelocity() const override
	{
		return ConnectedSpline.Spline.WorldLocation;
	}
}