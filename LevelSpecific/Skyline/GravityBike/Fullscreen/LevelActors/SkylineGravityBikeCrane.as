enum ESkylineGravityBikeCraneMovementMode
{
	None,
	SplineBased,
	Manual,
};

struct FSkylineGravityBikeCraneTarget
{
	UPROPERTY()
	float TargetHeight = 0;

	UPROPERTY()
	float TargetYaw = 0;

	UPROPERTY()
	float TargetPitch = 0;
};

UCLASS(Abstract)
class ASkylineGravityBikeCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent CranePitchRoot;

	UPROPERTY(DefaultComponent, Attach = CranePitchRoot)
	USceneComponent CraneTowerHeightRoot;

	UPROPERTY(DefaultComponent, Attach = CraneTowerHeightRoot)
	USceneComponent CraneYawRoot;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineInheritMovementComponent InheritMovementComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USkylineGravityBikeCraneEditorComponent EditorComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Spline Based Movement")
	AGravityBikeSplineActor Spline;

	/**
	 * How long should it take to reach the desired alpha?
	 * Required to smooth out any pops when entering the spline
	 */
	UPROPERTY(EditAnywhere, Category = "Spline Based Movement")
	float ReachSplineAlphaDuration = 1;

	UPROPERTY(EditAnywhere, Category = "Spline Based Movement|Height")
	FRuntimeFloatCurve CraneHeightCurve;
	default CraneHeightCurve.AddDefaultKey(0, 0);
	default CraneHeightCurve.AddDefaultKey(1, 1);

	UPROPERTY(EditAnywhere, Category = "Spline Based Movement|Yaw")
	FRuntimeFloatCurve CraneYawCurve;
	default CraneYawCurve.AddDefaultKey(0, 0);
	default CraneYawCurve.AddDefaultKey(1, 1);

	UPROPERTY(EditAnywhere, Category = "Spline Based Movement|Pitch")
	FRuntimeFloatCurve CranePitchCurve;
	default CranePitchCurve.AddDefaultKey(0, 0);
	default CranePitchCurve.AddDefaultKey(1, 0);

	UPROPERTY(EditAnywhere, Category = "Manual Movement")
	bool bUseManualMoveStart = false;

	UPROPERTY(EditAnywhere, Category = "Manual Movement")
	float ManualMoveDuration = 3;

	UPROPERTY(EditInstanceOnly, Category = "Manual Movement")
	FSkylineGravityBikeCraneTarget ManualMoveStart;

	UPROPERTY(EditAnywhere, Category = "Manual Movement")
	FSkylineGravityBikeCraneTarget ManualMoveTarget;

	private ESkylineGravityBikeCraneMovementMode MovementMode = ESkylineGravityBikeCraneMovementMode::None;

	FHazeAcceleratedFloat AccHeight;
	FHazeAcceleratedFloat AccPitch;
	FHazeAcceleratedFloat AccYaw;

	// Spline
	private float SplineAlpha = 0;
	private bool bIsCurrentSpline = false;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Preview")
	ESkylineGravityBikeCraneMovementMode PreviewMode = ESkylineGravityBikeCraneMovementMode::SplineBased; 

	UPROPERTY(EditInstanceOnly, Category = "Preview", Meta = (EditCondition = "PreviewMode == ESkylineGravityBikeCraneMovementMode::SplineBased", ClampMin = "0.0", ClampMax = "1.0"))
	float SplinePreviewAlpha = 0;

	void EditorTick(float DeltaTime)
	{
		switch(PreviewMode)
		{
			case ESkylineGravityBikeCraneMovementMode::None:
				AccHeight.AccelerateToWithStop(ManualMoveStart.TargetHeight, ManualMoveDuration, DeltaTime, 0.01);
				AccYaw.AccelerateToWithStop(ManualMoveStart.TargetYaw, ManualMoveDuration, DeltaTime, 0.01);
				AccPitch.AccelerateToWithStop(ManualMoveStart.TargetPitch, ManualMoveDuration, DeltaTime, 0.01);
				break;

			case ESkylineGravityBikeCraneMovementMode::SplineBased:
			{
				float TargetHeight = 0;
				float TargetYaw = 0;
				float TargetPitch = 0;
				GetSplineTargets(SplinePreviewAlpha, TargetHeight, TargetYaw, TargetPitch);

				AccHeight.AccelerateToWithStop(TargetHeight, ReachSplineAlphaDuration, DeltaTime, 0.01);
				AccYaw.AccelerateToWithStop(TargetYaw, ReachSplineAlphaDuration, DeltaTime, 0.01);
				AccPitch.AccelerateToWithStop(TargetPitch, ReachSplineAlphaDuration, DeltaTime, 0.01);
				break;
			}

			case ESkylineGravityBikeCraneMovementMode::Manual:
			{
				AccHeight.AccelerateToWithStop(ManualMoveTarget.TargetHeight, ManualMoveDuration, DeltaTime, 0.01);
				AccYaw.AccelerateToWithStop(ManualMoveTarget.TargetYaw, ManualMoveDuration, DeltaTime, 0.01);
				AccPitch.AccelerateToWithStop(ManualMoveTarget.TargetPitch, ManualMoveDuration, DeltaTime, 0.01);
				break;
			}
		}

		UpdateTransforms();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!ensure(Spline != nullptr, f"No spline assigned on {this}!"))
			return;

		float TargetHeight = 0;
		float TargetYaw = 0;
		float TargetPitch = 0;

		if(bUseManualMoveStart)
		{
			TargetHeight = ManualMoveStart.TargetHeight;
			TargetYaw = ManualMoveStart.TargetYaw;
			TargetPitch = ManualMoveStart.TargetPitch;
		}
		else
		{
			GetSplineTargets(0, TargetHeight, TargetYaw, TargetPitch);
		}

		AccHeight.SnapTo(TargetHeight);
		AccYaw.SnapTo(TargetYaw);
		AccPitch.SnapTo(TargetPitch);

		UpdateTransforms();

		Spline.OnBecomeCurrentSpline.AddUFunction(this, n"OnBecomeCurrentSpline");
		Spline.OnLoseBeingCurrentSpline.AddUFunction(this, n"OnLoseBeingCurrentSpline");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		switch(MovementMode)
		{
			case ESkylineGravityBikeCraneMovementMode::None:
				break;

			case ESkylineGravityBikeCraneMovementMode::SplineBased:
				TickSplineBasedMovement(DeltaSeconds);
				break;

			case ESkylineGravityBikeCraneMovementMode::Manual:
				TickManualMovement(DeltaSeconds);
				break;
		}
	}

	private void TickSplineBasedMovement(float DeltaTime)
	{
		float TargetHeight = 0;
		float TargetYaw = 0;
		float TargetPitch = 0;

		if(bIsCurrentSpline)
		{
			const float DistanceAlongSpline = GravityBikeSpline::GetGravityBikeDistanceAlongSpline(Spline);
			const float NewAlpha = Math::Saturate(DistanceAlongSpline / Spline.SplineComp.SplineLength);
			SplineAlpha = Math::Max(NewAlpha, SplineAlpha);

			GetSplineTargets(SplineAlpha, TargetHeight, TargetYaw, TargetPitch);

			AccHeight.AccelerateToWithStop(TargetHeight, ReachSplineAlphaDuration, DeltaTime, 0.01);
			AccYaw.AccelerateToWithStop(TargetYaw, ReachSplineAlphaDuration, DeltaTime, 0.01);
			AccPitch.AccelerateToWithStop(TargetPitch, ReachSplineAlphaDuration, DeltaTime, 0.01);
		}
		else
		{
			GetSplineTargets(1, TargetHeight, TargetYaw, TargetPitch);
		}

		UpdateTransforms();

		if(!bIsCurrentSpline && HasReachedTargets(TargetHeight, TargetYaw, TargetPitch))
		{
			// We have reached our target, stop ticking
			SetActorTickEnabled(false);

			if(MovementMode != ESkylineGravityBikeCraneMovementMode::None)
			{
				OnStopMoving();
				MovementMode = ESkylineGravityBikeCraneMovementMode::None;
			}
		}
	}

	private void TickManualMovement(float DeltaTime)
	{
		AccHeight.AccelerateToWithStop(ManualMoveTarget.TargetHeight, ManualMoveDuration, DeltaTime, 0.01);
		AccYaw.AccelerateToWithStop(ManualMoveTarget.TargetYaw, ManualMoveDuration, DeltaTime, 0.01);
		AccPitch.AccelerateToWithStop(ManualMoveTarget.TargetPitch, ManualMoveDuration, DeltaTime, 0.01);

		UpdateTransforms();

		if(HasReachedTargets(ManualMoveTarget.TargetHeight, ManualMoveTarget.TargetYaw, ManualMoveTarget.TargetPitch))
		{
			// We have reached our target, stop ticking
			SetActorTickEnabled(false);

			if(MovementMode != ESkylineGravityBikeCraneMovementMode::None)
			{
				OnStopMoving();
				MovementMode = ESkylineGravityBikeCraneMovementMode::None;
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartManualMove()
	{
		SetActorTickEnabled(true);

		if(MovementMode == ESkylineGravityBikeCraneMovementMode::None)
			OnStartMoving();

		MovementMode = ESkylineGravityBikeCraneMovementMode::Manual;
	}

	UFUNCTION()
	private void OnBecomeCurrentSpline()
	{
		bIsCurrentSpline = true;
		SetActorTickEnabled(true);

		if(MovementMode == ESkylineGravityBikeCraneMovementMode::None)
			OnStartMoving();

		MovementMode = ESkylineGravityBikeCraneMovementMode::SplineBased;
	}

	UFUNCTION()
	private void OnLoseBeingCurrentSpline()
	{
		bIsCurrentSpline = false;
	}

	void GetSplineTargets(float InSplineAlpha, float&out OutTargetHeight, float&out OutTargetYaw, float&out OutTargetPitch) const
	{
		OutTargetHeight = CraneHeightCurve.GetFloatValue(InSplineAlpha);
		OutTargetYaw = CraneYawCurve.GetFloatValue(InSplineAlpha);
		OutTargetPitch = CranePitchCurve.GetFloatValue(InSplineAlpha);
	}

	bool HasReachedTargets(float TargetHeight, float TargetYaw, float TargetPitch) const
	{
		if(!Math::IsNearlyEqual(AccHeight.Value, TargetHeight))
			return false;

		if(!Math::IsNearlyEqual(AccYaw.Value, TargetYaw))
			return false;

		if(!Math::IsNearlyEqual(AccPitch.Value, TargetPitch))
			return false;

		return true;
	}

	void UpdateTransforms()
	{
		CraneTowerHeightRoot.SetRelativeLocation(FVector(0, 0, AccHeight.Value));
		CraneYawRoot.SetRelativeRotation(FRotator(0, AccYaw.Value, 0));
		CranePitchRoot.SetRelativeRotation(FRotator(AccPitch.Value, 0, 0));
	}

	void OnStartMoving()
	{
		USkylineGravityBikeCraneEventHandler::Trigger_OnStartMoving(this);
	}

	void OnStopMoving()
	{
		USkylineGravityBikeCraneEventHandler::Trigger_OnStopMoving(this);
	}
};

UCLASS(Abstract)
class USkylineGravityBikeCraneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
};

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class USkylineGravityBikeCraneEditorComponent : UActorComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(World.WorldType != EWorldType::Editor)
			return;

		auto Crane = Cast<ASkylineGravityBikeCrane>(Owner);
		Crane.EditorTick(DeltaSeconds);
	}
};

class USkylineGravityBikeCraneEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineGravityBikeCraneEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Crane = Cast<ASkylineGravityBikeCrane>(Component.Owner);
		if(Crane == nullptr)
			return;

		switch(Crane.PreviewMode)
		{
			case ESkylineGravityBikeCraneMovementMode::None:
				break;

			case ESkylineGravityBikeCraneMovementMode::SplineBased:
			{
				if(Crane.Spline == nullptr)
					return;

				if(Crane.Spline.AttachParentActor == Crane)
				{
					// Move crane to 0 alpha location
					// Crane.UpdateTransforms();
					FVector OriginalWorldLocation = Crane.Spline.SplineComp.GetWorldLocationAtSplineFraction(Crane.SplinePreviewAlpha);
					// FVector OriginalRelativeLocation = Crane.CraneYawRoot.WorldTransform.InverseTransformPosition(OriginalWorldLocation);
					// Crane.UpdateTransforms(Crane.AccAlpha.Value);
					// FVector CurrentWorldLocation = Crane.CraneYawRoot.WorldTransform.TransformPosition(OriginalRelativeLocation);

					DrawPoint(OriginalWorldLocation, FLinearColor::Green, 50);
					//DrawPoint(CurrentWorldLocation, FLinearColor::Red, 50);
				}
				else
				{
					DrawPoint(Crane.Spline.SplineComp.GetWorldLocationAtSplineFraction(Crane.SplinePreviewAlpha), FLinearColor::Red, 50);
				}
				
				break;
			}

			case ESkylineGravityBikeCraneMovementMode::Manual:
				break;
		}
	}
};
#endif