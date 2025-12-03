
class ABabyDragonZiplinePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBabyDragonZiplineTargetable ZiplineTargetable;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif
	UPROPERTY(EditAnywhere, Category = "Zipline")
	AHazeCameraActor ZiplineCamera;

	UPROPERTY(EditAnywhere, Category = "Zipline")
	float CameraBlendInTime = 2.0;

	UPROPERTY(EditAnywhere, Category = "Zipline")
	float CameraBlendOutTime = 1.0;

	UPROPERTY(EditAnywhere, Category = "Zipline")
	AHazeActor SplineActor;

	UPROPERTY(EditAnywhere, Category = "Zipline")
	float MaxEnterRange = BabyDragonZipline::ZiplineEnterRange;

	UPROPERTY(EditAnywhere, Category = "Zipline")
	float VisibleRange = BabyDragonZipline::VisibleRange;

	UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
			SplineComp = Spline::GetGameplaySpline(SplineActor, this);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor != nullptr)
		{
			SplineComp = UHazeSplineComponent::Get(SplineActor);
			if (SplineComp != nullptr)
			{
				SplineComp.EditingSettings.bVisualizeDirection = true;
			}
		}
	}
};

class UBabyDragonZiplineTargetable : UTargetableComponent
{
	default TargetableCategory = n"PrimaryLevelAbility";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	ABabyDragonZiplinePoint ZiplinePoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ZiplinePoint = Cast<ABabyDragonZiplinePoint>(Owner);
	}

	float GetEnterDistanceOnSpline(AHazePlayerCharacter Player) const
	{
		FVector TestLocation = Player.ActorLocation;
		TestLocation += Player.ViewRotation.ForwardVector * 300.0;

		float ClosestSplineDistance = ZiplinePoint.SplineComp.GetClosestSplineDistanceToWorldLocation(TestLocation);
		return ClosestSplineDistance;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (ZiplinePoint.SplineComp == nullptr)
			return false;

		FSphere SplineBounds = ZiplinePoint.SplineComp.GetSplineBounds();
		float BoundsDistanceSQ = SplineBounds.Center.DistSquared(Query.Player.ActorLocation);

		// Ignore splines that cannot be close enough to enter due to their bounds
		if (BoundsDistanceSQ > Math::Square(SplineBounds.W + ZiplinePoint.VisibleRange))
			return false;

		// Can't enter if we're already on the zipline
		auto DragonComp = UPlayerTailBabyDragonComponent::Get(Query.Player);
		if (DragonComp.ZiplineActivePoint == Owner)
			return false;

		// Compute distance to the closest point on the spline
		float ClosestSplineDistance = GetEnterDistanceOnSpline(Query.Player);
		FTransform SplineTransform = ZiplinePoint.SplineComp.GetWorldTransformAtSplineDistance(ClosestSplineDistance);

		// We can't enter a zipline from the wrong end
		if (ClosestSplineDistance >= ZiplinePoint.SplineComp.GetSplineLength() - 50.0)
			return false;

		// Check if we're at the right distances or not
		Query.DistanceToTargetable = SplineTransform.Location.Distance(Query.Player.ActorLocation);
		Targetable::ApplyVisibleRange(Query, ZiplinePoint.VisibleRange);
		Targetable::ApplyTargetableRange(Query, ZiplinePoint.MaxEnterRange);
		Targetable::ApplyVisualProgressFromRange(Query, ZiplinePoint.VisibleRange, ZiplinePoint.MaxEnterRange);

		// We can't activate points that are behind us
		FVector DirectionToPoint = (SplineTransform.Location - Query.Player.ViewLocation).GetSafeNormal();
		float DotToCamera = Query.Player.ViewRotation.ForwardVector.DotProduct(DirectionToPoint);
		if (DotToCamera < 0.2)
			return false;

		// We can't go backwards on a zipline
		float ZiplineForwardYaw = SplineTransform.Rotator().Yaw;
		float ViewForwardYaw = Query.Player.ViewRotation.Yaw;
		float AngleDifference = Math::FindDeltaAngleDegrees(ZiplineForwardYaw, ViewForwardYaw);
		if (AngleDifference > BabyDragonZipline::EnterMaximumAllowedAngleFromForward)
			return false;

		Query.DistanceToTargetable = SplineTransform.Location.Distance(Query.Player.ActorLocation);
		Targetable::ApplyDistanceToScore(Query);

		// TODO: Score based on camera here as well
		return true;
	}

	FVector CalculateWidgetVisualOffset(AHazePlayerCharacter Player, UTargetableWidget Widget) const override
	{
		float ClosestSplineDistance = GetEnterDistanceOnSpline(Player);
		FVector SplinePosition = ZiplinePoint.SplineComp.GetWorldLocationAtSplineDistance(ClosestSplineDistance);

		return WorldTransform.InverseTransformPosition(SplinePosition) + WidgetVisualOffset;
	}
}