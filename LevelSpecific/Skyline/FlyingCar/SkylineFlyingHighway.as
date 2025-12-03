// Defines the way the car will be constrained during spline movement
enum ESkylineFlyingHighwayMovementConstraint
{
	Corridor,
	Tunnel
}

struct FSkylineFlyingHighwayQuery
{
	ASkylineFlyingCar Car;

	float InputScore;
	float CameraScore;
	float DistanceScore;
	float MovementScore;

	FSkylineFlyingHighwayQuery(ASkylineFlyingCar FlyingCar)
	{
		Car = FlyingCar;
	}

	float GetFinalScore() const
	{
		return DistanceScore + InputScore + CameraScore + MovementScore;
	}

	float GetSplineGrabDistance() const
	{
		return USkylineFlyingCarGotySettings::GetSettings(Car).SplineMovementSplineGrabDistance;
	}

	int opCmp(const FSkylineFlyingHighwayQuery& OtherQuery) const
	{
		if (GetFinalScore() > OtherQuery.GetFinalScore())
			return 1;

		if (GetFinalScore() == OtherQuery.GetFinalScore())
			return 0;

		return -1;
	}
}

UCLASS(Abstract)
class ASkylineFlyingHighway : APropLine
{
	default bGameplaySpline = true;

#if EDITOR
	default PropSpline.bRenderWhileNotSelected = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorSkylineFlyingHighwayDebugComponent DebugComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// Multiplier on the movement settings
	UPROPERTY(EditAnywhere)
	float MovementSpeedScale = 1.0;

	// Multiplier on the steering speed
	UPROPERTY(EditAnywhere)
	float SteeringSpeedScale = 1.0;

	// Whether we can escape highway by means of boosting
	UPROPERTY(EditAnywhere)
	bool bCanBoostAwayFromHighway = false;

	// The kind of volume that will be used as bounds
	UPROPERTY(EditAnywhere)
	ESkylineFlyingHighwayMovementConstraint MovementConstraintType = ESkylineFlyingHighwayMovementConstraint::Tunnel;

	// How big is the tunnel
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel", EditConditionHides))
	float TunnelRadius = 1300.0;

	// How wide the corridor is
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Corridor", EditConditionHides))
	float CorridorWidth = 800.0;

	// How tall the corridor is
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Corridor", EditConditionHides))
	float CorridorHeight = 2600.0;

	private bool bEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
		{
			CorridorWidth = TunnelRadius;
			CorridorHeight = TunnelRadius;
		}
	}

	// Score based on player distance
	bool Evaluate(FSkylineFlyingHighwayQuery& Query) const
	{
		if (!IsEnabled())
			return false;

		const ASkylineFlyingCar Car = Query.Car;

		FVector CarLocation = Car.ActorLocation + Car.ActorVelocity * Time::GetActorDeltaSeconds(Car);

		FSplinePosition SplinePosition = HighwaySpline.GetClosestSplinePositionToWorldLocation(CarLocation, false);
		FVector SplineToCar = CarLocation - SplinePosition.WorldLocation;

		// Need to adjust spline location to highway border
		FVector ClosestSplineLocation = GetClosestSplineLocation(SplineToCar, SplinePosition);
		FVector CarToClosestSplineLocation = ClosestSplineLocation - CarLocation;
		float DistanceFraction = CarToClosestSplineLocation.Size() / Query.GetSplineGrabDistance();
		if (DistanceFraction > 1.0)
			return false;

		// Add distance score to closest location
		Query.DistanceScore = 1.0 - DistanceFraction;

		// Add bias towards current highway
		// if (Query.Car.ActiveHighway == this)
		// 	Query.DistanceScore += 1.0;

		// Add distance score to spline position
		Query.DistanceScore += 1.0 - Math::Saturate(SplineToCar.Size() / Query.GetSplineGrabDistance());

		// Input score
		FVector ProjectedInput = (Query.Car.ActorUpVector * Query.Car.PitchInput + Query.Car.ActorRightVector * Query.Car.YawInput);
		Query.InputScore = Math::Saturate(ProjectedInput.DotProduct(-SplineToCar.GetSafeNormal()));

		// Camera score
		// Query.CameraScore = Query.Car.Pilot.ViewRotation.ForwardVector.DotProduct(CarToSplineNormal);

		// Movement score: are we heading with spline's course?
		Query.MovementScore = Query.Car.ActorVelocity.GetSafeNormal().DotProduct(SplinePosition.WorldForwardVector);

		// Debug::DrawDebugString(ClosestSplineLocation - SplineToCar * 0.5, "score: " + Query.GetFinalScore(), FLinearColor::DPink);
		// Debug::DrawDebugString(ClosestSplineLocation - SplineToCar * 0.5, " distance " + Query.DistanceScore +
		// 																				   "\n input  " + Query.InputScore, ScreenSpaceOffset = FVector2D(10, 28));

		// Debug::DrawDebugDirectionArrow(ClosestSplineLocation, SplinePosition.WorldLocation - ClosestSplineLocation, (SplinePosition.WorldLocation - ClosestSplineLocation).Size(), 10000, FLinearColor(SplinePosition.CurrentSpline.Owner.ActorLocation.Abs * 0.00001));

		return true;
	}

	// Finds closest point to highway taking into account it constraint volume
	FVector GetClosestSplineLocation(FVector SplineToCar, const FSplinePosition& SplinePosition) const
	{
		FVector HorizontalOffset = SplineToCar.ConstrainToDirection(SplinePosition.WorldRightVector).GetClampedToMaxSize(CorridorWidth);
		FVector VerticalOffset = SplineToCar.ConstrainToDirection(SplinePosition.WorldUpVector).GetClampedToMaxSize(CorridorHeight);
		return SplinePosition.WorldLocation + HorizontalOffset + VerticalOffset;
	}

	UHazeSplineComponent GetHighwaySpline() const property
	{
		auto SplineComp = Spline::GetGameplaySpline(this, this);
		return SplineComp;
	}

	float GetRadius() const
	{
		if (MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
			return TunnelRadius;

		return CorridorWidth;
	}

	void SetEnabled(bool bValue)
	{
		bEnabled = bValue;
	}

	bool IsEnabled() const
	{
		return bEnabled;
	}
}

class ASkylineFlyingHighwayActivationZone : AVolume
{
	default BrushComponent.LineThickness = 2.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
    default Shape::SetVolumeBrushColor(this, FLinearColor::White);


	// The highway to activate for the car
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	ASkylineFlyingHighway HighwayToActivate;

	UPROPERTY(DefaultComponent)
	UEditorSkylineFlyingHighwayDebugComponent DebugComponent;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if(HighwayToActivate == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		auto PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if(PilotComponent == nullptr)
			return;

		PilotComponent.Car.SetActiveHighway(HighwayToActivate);
	}
}

class UEditorSkylineFlyingHighwayDebugComponent : USceneComponent
{
	default bIsEditorOnly = true;

	UPROPERTY(EditAnywhere)
	bool bShowDebug = true;
}

#if EDITOR
class UEditorSkylineFlyingHighwayDebugComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UEditorSkylineFlyingHighwayDebugComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto Comp = Cast<UEditorSkylineFlyingHighwayDebugComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		if(!Comp.bShowDebug)
			return;
		
		// This belongs to a zones
		auto Zone = Cast<ASkylineFlyingHighwayActivationZone>(Comp.GetOwner());
		if(Zone != nullptr)
		{
			if(Zone.HighwayToActivate != nullptr)
			{
				FSplinePosition SplinePosition = Zone.HighwayToActivate.GetHighwaySpline().GetClosestSplinePositionToWorldLocation(Zone.GetActorLocation());
				DrawArrow(Zone.ActorLocation, SplinePosition.WorldLocation, FLinearColor::Green, 50.0, 10.0);
			}
		}
		// This belongs to a highway spline
		else
		{
			auto Highway = Cast<ASkylineFlyingHighway>(Component.Owner);
			auto Spline = Highway.GetHighwaySpline();

			FSplinePosition SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(GetEditorViewLocation() + (GetEditorViewRotation().ForwardVector * 2000.0));
			if (Highway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
			{
				FQuat Rotation = FQuat(SplinePosition.WorldRightVector, PI / 2) * SplinePosition.WorldRotation;
				DrawWireCylinder(SplinePosition.WorldLocation, Rotation.Rotator(), FLinearColor::Blue, Highway.TunnelRadius, 500.0, 24.0, 4.0);
			}
			else if (Highway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Corridor)
			{
				DrawWireBox(SplinePosition.WorldLocation, FVector(500, Highway.CorridorWidth, Highway.CorridorHeight ), SplinePosition.WorldRotation, FLinearColor::Yellow, 10.0);
			}

			FVector ArrowLocation = SplinePosition.WorldLocation + (GetEditorViewRotation().UpVector * 100.0);
			FVector ArrowDelta = SplinePosition.WorldForwardVector * 500.0;
			DrawArrow(ArrowLocation - ArrowDelta, ArrowLocation + ArrowDelta, FLinearColor::Blue, 100.0, 10.0);
		}
    }   
} 
#endif