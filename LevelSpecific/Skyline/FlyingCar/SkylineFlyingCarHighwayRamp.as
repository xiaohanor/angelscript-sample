class ASkylineFlyingCarHighwayRamp : ASkylineFlyingHighway
{
	default MovementConstraintType = ESkylineFlyingHighwayMovementConstraint::Corridor;
	default CorridorHeight = 20.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USkylineFlyingCarHighwayRampVisualizerComponent VisualizerComponent;
#endif

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	private FVector JumpTargetLocation;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	float JumpHeight = 500.0;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY(EditInstanceOnly)
	FRuntimeFloatCurve FloatCurve;

	UPROPERTY(EditAnywhere, Category = "HUD")
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UPROPERTY(EditAnywhere, Category = "Force Feedback")
	UForceFeedbackEffect RampBoostEndFF;

	float StartingSpeedScale;

 	UFUNCTION(BlueprintOverride)
 	void BeginPlay()
 	{
 		Super::BeginPlay();
		StartingSpeedScale =  MovementSpeedScale;
 	}

	UFUNCTION(BlueprintCallable)
	void SetpeedScale()
	{	
		ActionQueComp.Duration(4.0, this, n"UpdateSpeedScale");
	}

	UFUNCTION()
	private void UpdateSpeedScale(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		MovementSpeedScale = Math::Lerp(StartingSpeedScale, 2.5, AlphaValue);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("SPeedScale: " + MovementSpeedScale);
	}

	FVector GetImpulseToReachJumpTarget(FVector StartLocation)
	{
		// Eman TODO: HAX
		float Gravity = USkylineFlyingCarGotySettings::GetSettings(this).GravityAmount;
		return Trajectory::CalculateParamsForPathWithHeight(StartLocation, GetWorldJumpTargetLocation(), Gravity, JumpHeight).Velocity;
	}

	FVector GetWorldJumpTargetLocation() const
	{
		return ActorTransform.TransformPosition(JumpTargetLocation);
	}

	// This guy is a special case due to the constraint
	FVector GetClosestSplineLocation(FVector SplineToCar, const FSplinePosition& SplinePosition) const override
	{
		FVector ConstrainedSplineToCar = SplineToCar.ConstrainToPlane(SplinePosition.WorldForwardVector).GetClampedToMaxSize(CorridorWidth + CorridorHeight);
		FVector ClosestSplineLocation = SplinePosition.WorldLocation + ConstrainedSplineToCar;

		return ClosestSplineLocation;
	}
}

class USkylineFlyingCarHighwayRampVisualizerComponent : UActorComponent {};
class USkylineFlyingCarHighwayRampVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineFlyingCarHighwayRampVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ASkylineFlyingCarHighwayRamp HighwayRamp = Cast<ASkylineFlyingCarHighwayRamp>(Component.Owner);
		if (HighwayRamp == nullptr)
			return;

		FVector StartLocation = HighwayRamp.ActorTransform.TransformPosition(HighwayRamp.HighwaySpline.SplinePoints.Last().RelativeLocation);
		FVector JumpImpulse = HighwayRamp.GetImpulseToReachJumpTarget(StartLocation);

		float TrajectoryLength = StartLocation.Distance(HighwayRamp.GetWorldJumpTargetLocation()) + HighwayRamp.JumpHeight;
		float Gravity = USkylineFlyingCarGotySettings::GetSettings(HighwayRamp).GravityAmount;

		auto TrajectoryPoints = Trajectory::CalculateTrajectory(StartLocation, TrajectoryLength, JumpImpulse, Gravity, 100);
		for (int i = 0; i < TrajectoryPoints.Num() - 1; i++)
		{
			DrawDashedLine(TrajectoryPoints.Positions[i], TrajectoryPoints.Positions[i + 1], FLinearColor::DPink, 1000, 100);
		}
	}
}