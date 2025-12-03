UCLASS(Abstract)
class ASkylineBossSpline : ASplineActor
{
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeScale = SplineWidth;

	UPROPERTY(EditAnywhere, Category = "Tripod Spline")
	float SplineWidth = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Tripod Spline")
	TSubclassOf<USkylineBossFootTargetComponent> FootTargetClass;

	UPROPERTY(EditAnywhere, Category = "Tripod Spline")
	float StepLength = 3500.0;

	UPROPERTY(EditAnywhere, Category = "Tripod Spline")
	bool bAllowManualAdjustTransforms;

	UPROPERTY(VisibleInstanceOnly, Category = "Tripod Spline")
	TArray<USkylineBossFootTargetComponent> FootTargets;

	UPROPERTY(VisibleAnywhere, Category = "Tripod Spline")
	TArray<FTransform> RelativeTransforms;

	const int Steps = 3;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CreateFootTargetComponents();

		// Never trace in ConstructionScript, because the terrain and other levels might not have loaded yet
		// Instead, we just use the saved relative transforms
		UpdateFootTargetComponentTransforms();
	}

	UFUNCTION(CallInEditor, Category = "Tripod Spline")
	void SaveTransformsFromComponents()
	{
		if (FootTargets.IsEmpty())
			return;

		for (int i = 0; i < RelativeTransforms.Num(); i++)
		{
			if (!RelativeTransforms.IsValidIndex(i))
				continue;

			if (!FootTargets.IsValidIndex(i))
				continue;

			RelativeTransforms[i].Location = FootTargets[i].RelativeLocation;
			RelativeTransforms[i].Rotation = FootTargets[i].RelativeRotation.Quaternion();
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Spline.UpdateSpline();
		Spline.EditingSettings.VisualizeScale = SplineWidth;

		if (!bAllowManualAdjustTransforms)
		{
			// Trace whenever we modify this actor so that the RelativeTransforms are kept up to date
			TraceAndFillRelativeTransforms();
		}
		else
		{
			SaveTransformsFromComponents();
		}

		// Don't create the components here, we only do that in ConstructionScript
		UpdateFootTargetComponentTransforms();
	}
#endif

	private int GetStepCount() const
	{
		const float Length = Spline.SplineLength;
		const int NumOfSteps = int(Length / StepLength);
		const int NumOfCycles = int(float(NumOfSteps) / Steps);
		return NumOfCycles * Steps;
	}

	/**
	 * Update the FootTargets array to match the Transforms in length
	 */
	private void CreateFootTargetComponents()
	{
		const int FootTargetCount = GetStepCount();

		// Make sure we have one foot target component per transform
		for (int i = 0; i < FootTargetCount; i++)
		{
			if(FootTargets.IsValidIndex(i))
			{
				if(IsValid(FootTargets[i]))
				{
					// We already have this foot target
					continue;
				}
				else
				{
					FootTargets[i] = nullptr;
				}
			}

			auto FootTarget = Cast<USkylineBossFootTargetComponent>(GetOrCreateComponent(FootTargetClass, FName("Target_" + i)));

			if(FootTargets.IsValidIndex(i))
			{
				// If we previously had a foot target in the array at this index, but it has been destroyed, replace it
				FootTargets[i] = FootTarget;
			}
			else
			{
				// If we have too few foot targets, add more
				FootTargets.Add(FootTarget);
			}
		}

		// If we have too many foot targets, remove the extra ones
		for(int i = FootTargets.Num() - 1; i >= FootTargetCount; i--)
		{
			if(FootTargets[i] != nullptr)
				FootTargets[i].DestroyComponent(this);

			FootTargets.RemoveAtSwap(i);
		}
	}

	/**
	 * Place the FootTarget components at the transforms
	 */
	private void UpdateFootTargetComponentTransforms()
	{
		if(RelativeTransforms.IsEmpty())
			return;

		for (int i = 0; i < FootTargets.Num(); i++)
		{
			if(FootTargets[i] == nullptr)
				continue;

			if(!RelativeTransforms.IsValidIndex(i))
				continue;

			FootTargets[i].SetRelativeLocationAndRotation(RelativeTransforms[i].Location, RelativeTransforms[i].Rotation);
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Tripod Spline")
	private void TraceAndFillRelativeTransformsOnAllSplines()
	{
		auto Actors = Editor::GetAllEditorWorldActorsOfClass(ASkylineBossSpline);
		for(auto Actor : Actors)
		{
			auto SplineActor = Cast<ASkylineBossSpline>(Actor);
			if(SplineActor == nullptr)
				continue;

			SplineActor.TraceAndFillRelativeTransforms();
		}
	}

	UFUNCTION(CallInEditor, Category = "Tripod Spline")
	private void TraceAndFillRelativeTransforms()
	{
		PrintToScreen("FootTargets Traced!", 10.0, FLinearColor::Yellow);

		RelativeTransforms.Reset();

		const int NumOfSteps = GetStepCount();
		const int NumOfCycles = int(float(NumOfSteps) / Steps);

		if (NumOfCycles == 0)
			return;

		float AdjustedStepLength = Spline.SplineLength / (NumOfSteps - 1);

		int k = -1;
		for (int j = 0; j < NumOfSteps; j++)
		{
			float Distance = j * AdjustedStepLength;
			FSplinePosition SplinePosition = Spline.GetSplinePositionAtSplineDistance(Distance);
			
			FTransform TransformAtDistance = SplinePosition.WorldTransform;

			float Offset = k * TransformAtDistance.Scale3D.Y * SplineWidth;

			TransformAtDistance.Location = TransformAtDistance.Location + TransformAtDistance.Rotation.RightVector * Offset;

			float TraceLength = 10000.0;
			auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			FVector TraceStart = TransformAtDistance.Location + FVector::UpVector * TraceLength;
			FVector TraceEnd = TraceStart - FVector::UpVector * TraceLength * 2.0;
			auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

			if (HitResult.bBlockingHit)
			{
				FTransform RelativeTransform;
				RelativeTransform.Location = ActorTransform.InverseTransformPosition(HitResult.Location);
				RelativeTransform.Rotation = ActorTransform.InverseTransformRotation(FQuat::MakeFromZX(HitResult.Normal, SplinePosition.WorldForwardVector));
				RelativeTransforms.Add(RelativeTransform);
			}

			k++;
			k = Math::WrapIndex(k, -1, 2);
		}		
	}
#endif
};