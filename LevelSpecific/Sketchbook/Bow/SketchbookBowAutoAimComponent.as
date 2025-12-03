class USketchbookBowAutoAimComponent : UTargetableComponent
{
	default TargetableCategory = n"SketchbookAutoAim";

	UPROPERTY(EditAnywhere)
	float Radius = 200;

	UPROPERTY(EditAnywhere)
	float PredictionModifier = 0.5;

	FVector AverageVelocity;

	UPROPERTY(EditDefaultsOnly)
	bool bTrackVerticalVelocityOnly = false;

	UHazeRawVelocityTrackerComponent RawVelocityTrackerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RawVelocityTrackerComp = UHazeRawVelocityTrackerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RawVelocityTrackerComp != nullptr)
		{
			AverageVelocity = Math::Lerp(AverageVelocity, RawVelocityTrackerComp.LastFrameTranslationVelocity, 0.1);

			if(bTrackVerticalVelocityOnly)
				AverageVelocity = FVector::UpVector * AverageVelocity.Z;

			//Debug::DrawDebugArrow(WorldLocation, WorldLocation + AverageVelocity);
		}
		else
		{
			AverageVelocity = Math::Lerp(AverageVelocity, Owner.ActorVelocity, 0.1);
		}
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(!Targetable::IsOnScreen(Query))
		{
			Query.Result.bVisible = false;
			Query.Result.bPossibleTarget = false;
			return false;
		}

		if(!Query.Result.bVisible)
			return false;

		USketchbookBowPlayerComponent BowComp = USketchbookBowPlayerComponent::Get(Query.Player);
		
		if(BowComp == nullptr)
			return false;

		if(BowComp.AimTrajectorySpline.Points.Num() < 2)
			return false;

		const float ClosestDistance = BowComp.AimTrajectorySpline.GetClosestSplineDistanceToLocation(WorldLocation);

		const FVector ClosestPointOnTrajectory = BowComp.AimTrajectorySpline.GetLocationAtDistance(ClosestDistance);

		float DistanceFromTrajectory = ClosestPointOnTrajectory.Distance(WorldLocation);


		if(DistanceFromTrajectory > Radius)
			return false;

		float Dot = BowComp.AimTrajectorySpline.GetDirectionAtDistance(ClosestDistance).DotProduct(FVector::DownVector);
		if(Dot > 0.5)
			return false;

		Query.Result.Score /= (Math::Max(DistanceFromTrajectory, 1.0) / 1000.0);

		return true;
	}
};

class USketchbookBowAutoAimComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USketchbookBowAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USketchbookBowAutoAimComponent AutoAimComp = Cast<USketchbookBowAutoAimComponent>(Component);
		DrawWireSphere(AutoAimComp.WorldLocation, AutoAimComp.Radius);
	}
};