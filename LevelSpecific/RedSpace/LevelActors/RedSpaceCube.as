event void FRedSpaceCubeStartEvent();
event void FRedSpaceCubeFinishEvent();

UCLASS(Abstract, HideCategories = "Rendering Actor Collision Cooking Debug")
class ARedSpaceCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CubeRoot;

	UPROPERTY(DefaultComponent, Attach = CubeRoot)
	UStaticMeshComponent CubeMesh;

	UPROPERTY(DefaultComponent, Attach = CubeRoot)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere, Category = "Default")
	bool bPreviewTarget = false;

	UPROPERTY(EditAnywhere, Category = "Default", Meta = (Delta = "25", UIMin = "25", UIMax = "800"))
	float Width = 400.0;

	UPROPERTY(EditAnywhere, Category = "Default", Meta = (Delta = "25", UIMin = "50", UIMax = "2000"))
	float Height = 400.0;

	UPROPERTY(EditAnywhere, Category = "Default")
	FVector Offset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Default")
	bool bPivotInCenter = false;

	UPROPERTY(EditAnywhere, Category = "Default")
	bool bDisableCube = false;

	UPROPERTY(EditAnywhere, Category = "Movement")
	bool bMove = false;

	UPROPERTY(EditAnywhere, Category = "Movement",  Meta = (EditCondition = "bMove", EditConditionHides))
	bool bMoveFromStart = true;

	UPROPERTY(EditAnywhere, Category = "Movement",  Meta = (MakeEditWidget, EditCondition = "bMove", EditConditionHides))
	FVector TargetLocation;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove", EditConditionHides))
	bool bMoveWithTimeLike = true;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove && bMoveWithTimeLike", EditConditionHides))
	FHazeTimeLike MoveTimeLike;
	default MoveTimeLike.Duration = 2.0;
	default MoveTimeLike.bCurveUseNormalizedTime = true;
	default MoveTimeLike.UseSmoothCurveZeroToOne();
	float CachedMoveAlpha = 0.0;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove && !bMoveWithTimeLike", EditConditionHides))
	float MoveSpeed = 800.0;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove", EditConditionHides))
	float MoveDelay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove", EditConditionHides))
	ASplineActor MoveSpline;
	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere, Category = "Movement", Meta = (EditCondition = "bMove && MoveSpline != nullptr", EditConditionHides, ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SplineStartFraction = 0.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	bool bRotate = false;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate", EditConditionHides))
	bool bRotateFromStart = true;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate", EditConditionHides))
	bool bRotateWithTimeLike = false;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate && bRotateWithTimeLike", EditConditionHides))
	FHazeTimeLike RotateTimeLike;
	default RotateTimeLike.Duration = 4.0;
	default RotateTimeLike.bFlipFlop = true;
	default RotateTimeLike.bCurveUseNormalizedTime = true;
	default RotateTimeLike.UseSmoothCurveZeroToOne();
	float CachedRotationAlpha = 0.0;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate", EditConditionHides))
	FRotator TargetRotation = FRotator::ZeroRotator;
	FRotator StartRotation = FRotator::ZeroRotator;
	FRotator EndRotation = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate", EditConditionHides))
	bool bRotateIncrementally = false;

	UPROPERTY(EditAnywhere, Category = "Rotation", Meta = (EditCondition = "bRotate", EditConditionHides))
	float RotateDelay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Scale")
	bool bScale = false;

	UPROPERTY(EditAnywhere, Category = "Scale", Meta = (EditCondition = "bScale", EditConditionHides))
	bool bScaleFromStart = true;

	UPROPERTY(EditAnywhere, Category = "Scale", Meta = (EditCondition = "bScale", EditConditionHides))
	FHazeTimeLike ScaleTimeLike;
	default ScaleTimeLike.Duration = 2.0;
	default ScaleTimeLike.bFlipFlop = true;
	default ScaleTimeLike.bCurveUseNormalizedTime = true;
	default ScaleTimeLike.UseSmoothCurveZeroToOne();
	float CachedScaleAlpha = 0.0;

	UPROPERTY(EditAnywhere, Category = "Scale", Meta = (EditCondition = "bScale", EditConditionHides))
	float MaxWidth = 600.0;

	UPROPERTY(EditAnywhere, Category = "Scale", Meta = (EditCondition = "bScale", EditConditionHides))
	float MaxHeight = 600.0;

	UPROPERTY(EditAnywhere, Category = "Scale", Meta = (EditCondition = "bScale", EditConditionHides))
	float ScaleDelay = 0.0;

	UPROPERTY()
	FRedSpaceCubeStartEvent OnStartedRotating;

	UPROPERTY()
	FRedSpaceCubeFinishEvent OnFinishedMoving;

	UPROPERTY()
	FRedSpaceCubeFinishEvent OnFinishedRotating;

	UPROPERTY()
	FRedSpaceCubeFinishEvent OnFinishedScaling;

	bool bMoving = false;
	bool bRotating = false;
	bool bScaling = false;

	TArray<FName> OriginalTags;

	FVector MoveStartLocation;

	private bool bMovingWithPrediction = false;
	private float MovePredictionTimeOffset = 0;

	private bool bRotatingWithPrediction = false;
	private float RotatePredictionTimeOffset = 0;

	private bool bScalingWithPrediction = false;
	private float ScalePredictionTimeOffset = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewTarget)
		{
			if (bMove)
				CubeRoot.SetRelativeLocation(TargetLocation);
			if (bRotate)
				CubeRoot.SetRelativeRotation(TargetRotation);
		}
		else
		{
			CubeRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		}

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(CubeRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		SetActorScale3D(FVector::OneVector);

		CubeMesh.SetRelativeScale3D(FVector(Width/100.0, Width/100.0, Height/100.0));
		
		CubeMesh.SetDefaultCustomPrimitiveDataFloat(0, Math::RandRange(0.0, 1.0));

		if (bPivotInCenter)
			CubeMesh.SetRelativeLocation(Offset + FVector(0.0, 0.0, -Height/2));
		else
			CubeMesh.SetRelativeLocation(Offset);

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
			Actor.AttachToComponent(CubeRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		if (bDisableCube)
		{
			CubeMesh.SetVisibility(false);
			CubeMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		else
		{
			CubeMesh.SetVisibility(true);
			CubeMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}

		if (MoveSpline != nullptr)
		{
			SetActorLocation(MoveSpline.Spline.GetWorldLocationAtSplineFraction(SplineStartFraction));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
			Actor.AttachToComponent(CubeRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		CubeRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);

		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.BindFinished(this, n"FinishMove");

		RotateTimeLike.BindUpdate(this, n"UpdateRotate");
		RotateTimeLike.BindFinished(this, n"FinishRotate");

		ScaleTimeLike.BindUpdate(this, n"UpdateScale");
		ScaleTimeLike.BindFinished(this, n"FinishScale");

		MoveStartLocation = CubeRoot.RelativeLocation;

		if (bMove && bMoveFromStart)
			StartMoving(bPredictionSynced = true);

		if (bRotate && bRotateFromStart)
			StartRotating(bPredictionSynced = true);

		if (bScale && bScaleFromStart)
			StartScaling(bPredictionSynced = true);
	}

	UFUNCTION()
	void ActivateEverything()
	{
		if (bMove)
			StartMoving();
		
		if (bRotate)
			StartRotating();

		if (bScale)
			StartScaling();
	}

	UFUNCTION()
	void SnapEverything()
	{
		SnapMove();
		SnapRotate();
		SnapScale();
	}

	UFUNCTION()
	void SnapMove()
	{
		CubeRoot.SetRelativeLocation(TargetLocation);
	}

	UFUNCTION()
	void SnapRotate()
	{
		CubeRoot.SetRelativeRotation(TargetRotation);
	}

	UFUNCTION()
	void SnapScale()
	{
		CubeRoot.SetRelativeScale3D(FVector(MaxWidth/Width, MaxWidth/Width, MaxHeight/Height));
	}

	UFUNCTION()
	void UpdateStartLocation()
	{
		MoveStartLocation = CubeRoot.RelativeLocation;
	}

	UFUNCTION()
	void StartMoving(bool bPredictionSynced = false)
	{
		if (bPredictionSynced && bMoveWithTimeLike)
		{
			bMovingWithPrediction = true;
			MovePredictionTimeOffset = -MoveDelay;
		}
		else if (MoveDelay != 0.0)
		{
			Timer::SetTimer(this, n"Move", MoveDelay);
		}
		else
		{
			Move();
		}
	}

	UFUNCTION()
	void ReverseMovement()
	{
		check(!bMovingWithPrediction);
		MoveTimeLike.Reverse();

		URedSpaceCubeEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION()
	void StartMoving_ResetTimeLike()
	{
		check(!bMovingWithPrediction);
		MoveTimeLike.PlayFromStart();

		URedSpaceCubeEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void Move()
	{
		if (bMoving)
			return;

		if (bMoveWithTimeLike)
			MoveTimeLike.Play();
		else
		{
			if (MoveSpline != nullptr)
				SplinePos = FSplinePosition(MoveSpline.Spline, MoveSpline.Spline.SplineLength * SplineStartFraction, true);

			bMoving = true;
		}

		URedSpaceCubeEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMove(float CurValue)
	{
		if (MoveSpline != nullptr)
		{
			FVector Loc = MoveSpline.Spline.GetWorldLocationAtSplineFraction(CurValue);
			SetActorLocation(Loc);
		}
		else
		{
			FVector Loc = Math::Lerp(MoveStartLocation, TargetLocation, CurValue);
			CubeRoot.SetRelativeLocation(Loc);
		}

		CachedMoveAlpha = CurValue;
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMove()
	{
		OnFinishedMoving.Broadcast();
	}

	UFUNCTION()
	void StartRotating(bool bPredictionSynced = false)
	{
		if (RotateTimeLike.IsPlaying() || bRotating || bRotatingWithPrediction)
			return;

		if (bPredictionSynced && !bRotateIncrementally)
		{
			bRotatingWithPrediction = true;
			RotatePredictionTimeOffset = -RotateDelay;

			StartRotation = CubeRoot.RelativeRotation;
			EndRotation = TargetRotation;
		}
		else if (RotateDelay != 0.0)
		{
			Timer::SetTimer(this, n"Rotate", RotateDelay);
		}
		else
		{
			Rotate();
		}
	}

	UFUNCTION()
	void ReverseRotation()
	{
		check(!bRotatingWithPrediction);
		RotateTimeLike.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void Rotate()
	{
		if (RotateTimeLike.IsPlaying() || bRotating)
			return;

		if (bRotateIncrementally)
		{
			StartRotation = CubeRoot.RelativeRotation;
			EndRotation = StartRotation + TargetRotation;
		}
		else
		{
			StartRotation = FRotator::ZeroRotator;
			EndRotation = TargetRotation;
		}

		if (bRotateWithTimeLike)
			RotateTimeLike.Play();
		else
			bRotating = true;

		OnStartedRotating.Broadcast();
	}

	UFUNCTION()
	private void UpdateRotate(float CurValue)
	{
		FRotator Rot = Math::LerpShortestPath(StartRotation, EndRotation, CurValue);
		CubeRoot.SetRelativeRotation(Rot);

		CachedRotationAlpha = CurValue;
	}

	UFUNCTION()
	private void FinishRotate()
	{
		OnFinishedRotating.Broadcast();
	}

	UFUNCTION()
	void StartScaling(bool bPredictionSynced = false)
	{
		if (bPredictionSynced)
		{
			bScalingWithPrediction = true;
			ScalePredictionTimeOffset = -ScaleDelay;
		}
		else if (ScaleDelay != 0.0)
		{
			Timer::SetTimer(this, n"Scale", ScaleDelay);
		}
		else
		{
			Scale();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Scale()
	{
		if (bScaling)
			return;

		bScaling = true;
		ScaleTimeLike.Play();
	}
	
	UFUNCTION()
	private void UpdateScale(float CurValue)
	{
		FVector CurScale = Math::Lerp(FVector::OneVector, FVector(MaxWidth/Width, MaxWidth/Width, MaxHeight/Height), CurValue);
		CubeRoot.SetRelativeScale3D(CurScale);

		CachedScaleAlpha = CurValue;
	}

	UFUNCTION()
	private void FinishScale()
	{
		OnFinishedScaling.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMoving)
		{
			if (MoveSpline != nullptr)
			{
				SplinePos.Move(MoveSpeed * DeltaTime);
				SetActorLocation(SplinePos.WorldLocation);
			}
			else
			{
				FVector Loc = Math::VInterpConstantTo(CubeRoot.RelativeLocation, TargetLocation, DeltaTime, MoveSpeed);
				CubeRoot.SetRelativeLocation(Loc);

				if (Loc.Equals(TargetLocation))
				{
					bMoving = false;
					OnFinishedMoving.Broadcast();
				}
			}
		}

		if (bMovingWithPrediction)
		{
			float AlphaValue;
			if (MoveTimeLike.bFlipFlop)
			{
				AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + MovePredictionTimeOffset) % (MoveTimeLike.Duration * 2.0)) / MoveTimeLike.Duration;
				if (AlphaValue > 1.0)
					AlphaValue = 2.0 - AlphaValue;
			}
			else
			{
				AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + MovePredictionTimeOffset) % MoveTimeLike.Duration) / MoveTimeLike.Duration;
			}

			if (MoveTimeLike.Curve.GetNumKeys() != 0)
				AlphaValue = MoveTimeLike.Curve.GetFloatValue(AlphaValue);
			UpdateMove(AlphaValue);
		}

		if (bRotating)
		{
			CubeRoot.AddLocalRotation(TargetRotation * DeltaTime);
		}

		if (bRotatingWithPrediction)
		{
			if (bRotateWithTimeLike)
			{
				float AlphaValue;
				if (RotateTimeLike.bFlipFlop)
				{
					AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + RotatePredictionTimeOffset) % (RotateTimeLike.Duration * 2.0)) / RotateTimeLike.Duration;
					if (AlphaValue > 1.0)
						AlphaValue = 2.0 - AlphaValue;
				}
				else
				{
					AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + RotatePredictionTimeOffset) % RotateTimeLike.Duration) / RotateTimeLike.Duration;
				}

				if (RotateTimeLike.Curve.GetNumKeys() != 0)
					AlphaValue = RotateTimeLike.Curve.GetFloatValue(AlphaValue);
				UpdateRotate(AlphaValue);
			}
			else
			{
				float RotationValue = (Time::PredictedGlobalCrumbTrailTime + RotatePredictionTimeOffset);
				CubeRoot.SetRelativeRotation(StartRotation.Quaternion() * (TargetRotation * RotationValue).Quaternion());
			}
		}

		if (bScalingWithPrediction)
		{
			float AlphaValue;
			if (ScaleTimeLike.bFlipFlop)
			{
				AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + ScalePredictionTimeOffset) % (ScaleTimeLike.Duration * 2.0)) / ScaleTimeLike.Duration;
				if (AlphaValue > 1.0)
					AlphaValue = 2.0 - AlphaValue;
			}
			else
			{
				AlphaValue = ((Time::PredictedGlobalCrumbTrailTime + ScalePredictionTimeOffset) % ScaleTimeLike.Duration) / ScaleTimeLike.Duration;
			}

			if (ScaleTimeLike.Curve.GetNumKeys() != 0)
				AlphaValue = ScaleTimeLike.Curve.GetFloatValue(AlphaValue);
			UpdateScale(AlphaValue);
		}
	}

	UFUNCTION()
	void RemovePlatformableTags()
	{
		CubeMesh.RemoveTag(ComponentTags::WallScrambleable);
		CubeMesh.RemoveTag(ComponentTags::WallRunnable);
		CubeMesh.RemoveTag(ComponentTags::LedgeGrabbable);
		CubeMesh.RemoveTag(ComponentTags::LedgeRunnable);
		CubeMesh.RemoveTag(ComponentTags::Walkable);
		CubeMesh.RemoveTag(ComponentTags::LedgeClimbable);
	}

	UFUNCTION()
	void ResetPlatformableTags()
	{
		CubeMesh.ResetTagToDefault(ComponentTags::WallScrambleable);
		CubeMesh.ResetTagToDefault(ComponentTags::WallRunnable);
		CubeMesh.ResetTagToDefault(ComponentTags::LedgeGrabbable);
		CubeMesh.ResetTagToDefault(ComponentTags::LedgeRunnable);
		CubeMesh.ResetTagToDefault(ComponentTags::Walkable);
		CubeMesh.ResetTagToDefault(ComponentTags::LedgeClimbable);
	}

	UFUNCTION()
	void Wiggle()
	{	
		Timer::SetTimer(this, n"WigglePosition", 0.01);
	}

	UFUNCTION()
	private void WigglePosition()
	{
		ActorLocation += FVector(0, 0, 0.01);
	}
}

class URedSpaceCubeEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartMoving() {}
}