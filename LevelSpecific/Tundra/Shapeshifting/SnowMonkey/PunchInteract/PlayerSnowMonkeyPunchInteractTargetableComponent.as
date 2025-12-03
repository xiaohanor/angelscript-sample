event void FTundraPlayerSnowMonkeyPunchInteractEvent(FVector PlayerLocation);

enum ETundraPlayerSnowMonkeyPunchInteractTeleportType
{
	Point,
	Line,
	Square,
	Circle,
	Spline
}

enum ETundraPlayerSnowMonkeyPunchInteractAnimationType
{
	None UMETA(Hidden),
	Single,
	Multi
}

class UTundraPlayerSnowMonkeyPunchInteractTargetableComponent : UTargetableComponent
{
	default TargetableCategory = ActionNames::PrimaryLevelAbility;
	default UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere)
	ETundraPlayerSnowMonkeyPunchInteractAnimationType AnimationType = ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AnimationType == ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi", EditConditionHides))
	int AmountOfPunchesToComplete = 3;

	UPROPERTY(EditAnywhere, Category = "Teleport Type")
	ETundraPlayerSnowMonkeyPunchInteractTeleportType TeleportType;

	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line", EditConditionHides))
	float LineExtents = 100.0;

	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square", EditConditionHides))
	FVector2D SquareExtents = FVector2D(100.0, 100.0);

	/* This amount will be subtracted from the corners of the square to not allow monkey to hit the very edge of something */
	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square", EditConditionHides))
	float SquareSubtractExtents = 20.0;

	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Circle", EditConditionHides))
	float CircleRadius = 100.0;

	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Spline", EditConditionHides))
	ASplineActor Spline;

	UPROPERTY(EditAnywhere, Category = "Teleport Type", Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square || TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Circle || TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Spline", EditConditionHides))
	bool bExpandShapeByMonkeyCapsuleRadius = true;

	UPROPERTY(EditAnywhere)
	TArray<AActor> IgnoreActorsForTrace;

	UPROPERTY(EditAnywhere)
	bool bDisallowIfInsideShape = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line", EditConditionHides))
	bool bDisallowIfBehindLine = false;

	UPROPERTY(EditAnywhere, Category = "Editor")
	float EditorLineThickness = 0.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "WidgetClass != nullptr", EditConditionHides))
	float VisibleRange = 1800.0;

	UPROPERTY(EditAnywhere)
	float TargetableRange = 800.0;

	/* If true, the targetable will be displayed when Mio isn't in monkey form and will trigger an auto shapeshift upon triggering a punch */
	UPROPERTY(EditAnywhere)
	bool bVisibleWhenNotMonkey = false;

	/* If monkey has ground impact with these actors the punch cannot be performed */
	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<AActor>> DisallowedGroundActors;

	UPROPERTY()
	FTundraPlayerSnowMonkeyPunchInteractEvent OnPunch;

	UPROPERTY()
	FTundraPlayerSnowMonkeyPunchInteractEvent OnCompletedPunch;

	int AmountOfPunchesPerformed = 0;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(SquareSubtractExtents > ActualSquareExtents.X)
			SquareSubtractExtents = ActualSquareExtents.X;

		if(SquareSubtractExtents > ActualSquareExtents.Y)
			SquareSubtractExtents = ActualSquareExtents.Y;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Query.Player);
		if(ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big && !bVisibleWhenNotMonkey)
			return false;

		FTransform Transform = GetTargetSnowMonkeyTransform();
		float Dist = Transform.Location.Distance(Query.PlayerLocation);
		CustomApplyVisibleRange(Query, Dist);
		CustomApplyTargetableRange(Query, Dist);

		if(bDisallowIfInsideShape && IsInsideShape())
			return false;

		if(bDisallowIfBehindLine && TeleportType == ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line)
		{
			float DistanceAhead = Transform.Rotation.ForwardVector.DotProduct(Game::Mio.ActorLocation - Transform.Location);
			if(DistanceAhead > 0.0)
				return false;
		}

		FVector StartLocation = Query.Player.ActorLocation;
		FVector EndLocation = Query.TargetableLocation;

		if(StartLocation.Equals(EndLocation))
			return false;

		auto MoveComp = UPlayerMovementComponent::Get(Query.Player);
		if(!MoveComp.HasGroundContact())
			return false;

		if(DisallowedGroundActors.Contains(MoveComp.GroundContact.Actor))
			return false;

		CustomRequirePlayerCanReachUnblocked(Query, true, true);
		return true;
	}

	bool NextPunchWillComplete() const
	{
		// If we have single animation type we will never complete this!
		if(AnimationType == ETundraPlayerSnowMonkeyPunchInteractAnimationType::Single)
			return false;

		if(AmountOfPunchesPerformed == AmountOfPunchesToComplete - 1)
			return true;

		return false;
	}

	float GetActualLineExtents() const property
	{
		return LineExtents;
	}

	FVector2D GetActualSquareExtents() const property
	{
		float MonkeyRadius = TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X;

		if(bExpandShapeByMonkeyCapsuleRadius)
			return FVector2D(SquareExtents.X + MonkeyRadius, SquareExtents.Y + MonkeyRadius);

		return SquareExtents;
	}

	float GetActualCircleRadius() const property
	{
		float MonkeyRadius = TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X;

		if(bExpandShapeByMonkeyCapsuleRadius)
			return CircleRadius + MonkeyRadius;

		return CircleRadius;
	}

	FVector CalculateWidgetVisualOffset(AHazePlayerCharacter Player, UTargetableWidget Widget) const override
	{
		FTransform Transform = GetTargetSnowMonkeyTransform();
		return WorldTransform.InverseTransformPosition(Transform.Location) + WidgetVisualOffset;
	}

	bool IsInsideShape(float ShapeMargin = -10.0) const
	{
		FVector Location = Game::Mio.ActorLocation.PointPlaneProject(WorldLocation, UpVector);
		switch(TeleportType)
		{
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Point:
			{
				return false;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line:
			{
				return false;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square:
			{
				FVector LocalLocation = WorldTransform.InverseTransformPositionNoScale(Location);
				FBox Box = FBox::BuildAABB(FVector::ZeroVector, FVector(ActualSquareExtents.X + ShapeMargin, ActualSquareExtents.Y + ShapeMargin, 0.0));
				return Box.IsInsideXY(LocalLocation);
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Circle:
			{
				FVector LocalLocation = WorldTransform.InverseTransformPositionNoScale(Location);
				return LocalLocation.Size() < ActualCircleRadius + ShapeMargin;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Spline:
			{
				if(!Spline.Spline.IsClosedLoop())
					return false;

				FTransform ClosestTransform = Spline.Spline.GetClosestSplineWorldTransformToWorldLocation(Location);
				FVector ClosestLocation = ClosestTransform.Location;
				ClosestLocation -= ClosestTransform.Rotation.RightVector * ShapeMargin;
				float Dot = ClosestTransform.Rotation.RightVector.DotProduct(Location - ClosestLocation);
				return Dot > 0.0;
			}
		}
	}

	FTransform GetTargetSnowMonkeyTransform() const
	{
		FVector Location = Game::Mio.ActorLocation;
		switch(TeleportType)
		{
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Point:
			{
				return WorldTransform;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line:
			{
				FVector TargetLocation;
				float TargetFraction;
				Math::ProjectPositionOnLineSegment(WorldLocation - RightVector * ActualLineExtents, WorldLocation + RightVector * ActualLineExtents, Location, TargetLocation, TargetFraction);
				return FTransform(WorldRotation, TargetLocation);
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square:
			{
				TArray<FVector> Corners;
				Corners.Add(WorldLocation - RightVector * ActualSquareExtents.X + ForwardVector * ActualSquareExtents.Y);
				Corners.Add(WorldLocation + RightVector * ActualSquareExtents.X + ForwardVector * ActualSquareExtents.Y);
				Corners.Add(WorldLocation + RightVector * ActualSquareExtents.X - ForwardVector * ActualSquareExtents.Y);
				Corners.Add(WorldLocation - RightVector * ActualSquareExtents.X - ForwardVector * ActualSquareExtents.Y);

				float ClosestSqrDist = MAX_flt;
				FTransform ClosestTransform;
				for(int i = 0; i < Corners.Num(); i++)
				{
					FVector A = Corners[i];
					FVector B = Corners[Math::WrapIndex(i + 1, 0, Corners.Num())];
					FVector AToBDir = (B - A).GetSafeNormal();
					A += AToBDir * SquareSubtractExtents;
					B -= AToBDir * SquareSubtractExtents;

					FVector TargetLocation;
					float TargetFraction;
					Math::ProjectPositionOnLineSegment(A, B, Location, TargetLocation, TargetFraction);
					float SqrDist = TargetLocation.DistSquared(Location);
					if(SqrDist < ClosestSqrDist)
					{
						ClosestSqrDist = SqrDist;
						ClosestTransform = FTransform(FRotator::MakeFromZY(FVector::UpVector, -AToBDir), TargetLocation);
					}
				}

				return ClosestTransform;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Circle:
			{
				FVector TargetToPlayer = Location - WorldLocation;
				FVector TargetToPlayerDirFlat = TargetToPlayer.GetSafeNormal2D();
				FVector TargetLocation = WorldLocation + TargetToPlayerDirFlat * ActualCircleRadius;
				return FTransform(FRotator::MakeFromZX(FVector::UpVector, -TargetToPlayerDirFlat), TargetLocation);
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Spline:
			{
				FTransform TargetTransform = Spline.Spline.GetClosestSplineWorldTransformToWorldLocation(Location);
				FVector TargetLocation = TargetTransform.Location;
				if(bExpandShapeByMonkeyCapsuleRadius)
					TargetLocation -= TargetTransform.Rotation.RightVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X;

				return FTransform(FRotator::MakeFromZX(FVector::UpVector, TargetTransform.Rotation.RightVector), TargetLocation);
			}
		}
	}

	// Pass in the distance manually since the distance will be to the target location instead of the actual targetable world location.
	void CustomApplyDistanceToScore(FTargetableQuery& Query, float Dist) const
	{
		if (!Query.bDistanceAppliedToScore)
		{
			Query.Result.Score /= (Math::Max(Dist, 1.0) / 1000.0);
			Query.bDistanceAppliedToScore = true;
		}
	}

	// Pass in the distance manually since the distance will be to the target location instead of the actual targetable world location.
	void CustomApplyTargetableRange(FTargetableQuery& Query, float Dist) const
	{
		// Make sure closer points have higher score
		CustomApplyDistanceToScore(Query, Dist);

		if (Dist > TargetableRange)
		{
			// Cannot be targeted from this distance
			Query.Result.bPossibleTarget = false;
		}
	}

	// Pass in the distance manually since the distance will be to the target location instead of the actual targetable world location.
	void CustomApplyVisibleRange(FTargetableQuery& Query, float Dist) const
	{
		// Make sure closer points have higher score
		CustomApplyDistanceToScore(Query, Dist);

		Query.bHasHandledVisibility = true;
		if (Dist > VisibleRange)
		{
			// Targetable is not visible from this distance
			Query.Result.bVisible = false;
			Query.Result.bPossibleTarget = false;
		}
	}

	// Trace to the target location instead of the targetable's world location
	bool CustomRequirePlayerCanReachUnblocked(FTargetableQuery& Query, bool bIgnoreOwner = true, bool bIgnoreAttachParent = false, float KeepDistanceAmount = 0) const
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

		Trace.IgnoreActors(IgnoreActorsForTrace);
		
		if(bIgnoreAttachParent && Query.Component.Owner.AttachParentActor != nullptr)
			Trace.IgnoreActor(Query.Component.Owner.AttachParentActor);

		FVector StartLocation = Query.Player.ActorLocation;
		auto PunchInteractTargetable = Cast<UTundraPlayerSnowMonkeyPunchInteractTargetableComponent>(Query.Component);
		FVector EndLocation = PunchInteractTargetable.GetTargetSnowMonkeyTransform().Location;

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
}

class UTundraPlayerSnowMonkeyPunchInteractTargetableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraPlayerSnowMonkeyPunchInteractTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const float LineThickness = 5.0;

		auto Targetable = Cast<UTundraPlayerSnowMonkeyPunchInteractTargetableComponent>(Component);
		 
		switch(Targetable.TeleportType)
		{
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Point:
			{
				if(Targetable.WidgetClass != nullptr)
					DrawWireSphere(Targetable.WorldLocation, Targetable.VisibleRange, FLinearColor::Purple, LineThickness);

				DrawWireSphere(Targetable.WorldLocation, Targetable.TargetableRange, FLinearColor::Blue, LineThickness);
				break;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Line:
			{
				FVector A = Targetable.WorldLocation - Targetable.RightVector * Targetable.ActualLineExtents;
				FVector B = Targetable.WorldLocation + Targetable.RightVector * Targetable.ActualLineExtents;
				DrawLine(A, B, FLinearColor::Red, LineThickness);

				if(Targetable.WidgetClass != nullptr)
					DrawWireCapsule(Targetable.WorldLocation, FRotator::MakeFromZ(A - B), FLinearColor::Purple, Targetable.VisibleRange, Targetable.VisibleRange + Targetable.ActualLineExtents, 16, LineThickness);

				DrawWireCapsule(Targetable.WorldLocation, FRotator::MakeFromZ(A - B), FLinearColor::Blue, Targetable.TargetableRange, Targetable.TargetableRange + Targetable.ActualLineExtents, 16, LineThickness);
				break;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Square:
			{
				TArray<FVector> Corners;
				Corners.Add(Targetable.WorldLocation - Targetable.RightVector * Targetable.ActualSquareExtents.X + Targetable.ForwardVector * Targetable.ActualSquareExtents.Y);
				Corners.Add(Targetable.WorldLocation + Targetable.RightVector * Targetable.ActualSquareExtents.X + Targetable.ForwardVector * Targetable.ActualSquareExtents.Y);
				Corners.Add(Targetable.WorldLocation + Targetable.RightVector * Targetable.ActualSquareExtents.X - Targetable.ForwardVector * Targetable.ActualSquareExtents.Y);
				Corners.Add(Targetable.WorldLocation - Targetable.RightVector * Targetable.ActualSquareExtents.X - Targetable.ForwardVector * Targetable.ActualSquareExtents.Y);

				for(int i = 0; i < Corners.Num(); i++)
				{
					FVector A = Corners[i];
					FVector B = Corners[Math::WrapIndex(i + 1, 0, Corners.Num())];
					FVector AToBDir = (B - A).GetSafeNormal();
					A += AToBDir * Targetable.SquareSubtractExtents;
					B -= AToBDir * Targetable.SquareSubtractExtents;

					float AToBDist = A.Distance(B);
					DrawLine(A, B, FLinearColor::Red, LineThickness);
					if(Targetable.WidgetClass != nullptr)
						DrawWireCapsule((A + B) * 0.5, FRotator::MakeFromZ(A - B), FLinearColor::Purple, Targetable.VisibleRange, Targetable.VisibleRange + AToBDist * 0.5, 16, LineThickness);

					DrawWireCapsule((A + B) * 0.5, FRotator::MakeFromZ(A - B), FLinearColor::Blue, Targetable.TargetableRange, Targetable.TargetableRange + AToBDist * 0.5, 16, LineThickness);
				}
				break;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Circle:
			{
				DrawCircle(Targetable.WorldLocation, Targetable.ActualCircleRadius, FLinearColor::Red, LineThickness, FVector::UpVector);

				if(Targetable.WidgetClass != nullptr)
					DrawCircle(Targetable.WorldLocation, Targetable.VisibleRange + Targetable.ActualCircleRadius, FLinearColor::Purple, LineThickness, FVector::UpVector);

				DrawCircle(Targetable.WorldLocation, Targetable.TargetableRange + Targetable.ActualCircleRadius, FLinearColor::Blue, LineThickness, FVector::UpVector);
				break;
			}
			case ETundraPlayerSnowMonkeyPunchInteractTeleportType::Spline:
			{
				const float StepSize = 50.0;
				for(float Dist = 0.0; Dist < Targetable.Spline.Spline.SplineLength; Dist += StepSize)
				{
					FTransform ATf = Targetable.Spline.Spline.GetWorldTransformAtSplineDistance(Dist);
					FTransform BTf = Targetable.Spline.Spline.GetWorldTransformAtSplineDistance(Dist + StepSize);
					FVector A = ATf.Location;
					FVector B = BTf.Location;

					if(Targetable.bExpandShapeByMonkeyCapsuleRadius)
					{
						A -= ATf.Rotation.RightVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X;
						B -= BTf.Rotation.RightVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X;

						DrawLine(A, B, FLinearColor::Red, LineThickness);
					}

					if(Targetable.WidgetClass != nullptr)
						DrawLine(A - ATf.Rotation.RightVector * Targetable.VisibleRange, B - BTf.Rotation.RightVector * Targetable.VisibleRange, FLinearColor::Purple, LineThickness);

					DrawLine(A - ATf.Rotation.RightVector * Targetable.TargetableRange, B - BTf.Rotation.RightVector * Targetable.TargetableRange, FLinearColor::Blue, LineThickness);
				}
				break;
			}
		}
	}
}