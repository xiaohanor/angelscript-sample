const FStatID STAT_PinballPredictionRecordTransformComponent_RecordTransform(n"PinballPredictionRecordTransformComponent_RecordTransform");
const FStatID STAT_PinballPredictionRecordTransformComponent_GetTransformAtTime(n"PinballPredictionRecordTransformComponent_GetTransformAtTime");

struct FPinballPredictionRecordedTransform
{
	FTransform RelativeTransform;
	float Time;

	FPinballPredictionRecordedTransform(const UPinballPredictionRecordTransformComponent RecordTransformComp, float InTime)
	{
		RelativeTransform = RecordTransformComp.AttachParent.RelativeTransform;
		Time = InTime;
	}
};

event void FPinballPredictionRecordTransformSubTick(uint FrameNumber, uint SubframeNumber, float PredictionTime);

/**
 * Will record the relative transform of the attach parent component and store it for use in the prediction
 * All actors that move in the level and influence the ball must implement this component so that their transform is correct in the prediction, which occurs in the past
 */
class UPinballPredictionRecordTransformComponent : USceneComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;

	TArray<FPinballPredictionRecordedTransform> RecordedTransforms;
	FPinballPredictionRecordedTransform InitialTransform;

	UPROPERTY(EditAnywhere)
	bool bRemoveHalfPing = true;

	UPROPERTY(EditAnywhere)
	bool bPlaybackInPrediction = true;

	FPinballPredictionRecordTransformSubTick OnSubTick;

	private bool bBoundEvents = false;
	private bool bIsPredicting = false;

#if EDITOR
	private int EditorMaxRecordings = 5000;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!ShouldRecord())
		{
			DestroyComponent(this);
			return;
		}

		BindEvents();

		RecordedTransforms.Reserve(Math::CeilToInt(Pinball::Prediction::RecordTransform::GetBufferDuration() / Pinball::Prediction::RecordTransform::SamplesPerSecond) + 5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		check(ShouldRecord());

		if(bIsPredicting)
			return;

		RecordTransform();
	}

	bool ShouldRecord() const
	{
		if(!Network::IsGameNetworked())
			return false;

		if(Pinball::GetBallPlayer().HasControl())
			return false;

		return true;
	}

	void RecordTransform()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictionRecordTransformComponent_RecordTransform);

		const float CurrentTime = Time::OtherSideCrumbTrailSendTimePrediction;
		FPinballPredictionRecordedTransform RecordedTransform(this, CurrentTime);

		if(!RecordedTransforms.IsEmpty() && Math::IsNearlyEqual(CurrentTime, RecordedTransforms.Last().Time))
		{
			RecordedTransforms[RecordedTransforms.Num() - 1] = RecordedTransform;
		}
		else
		{
			RecordedTransforms.Add(RecordedTransform);
		}

#if EDITOR
		TEMPORAL_LOG("Recorded Transform")
			.Section(f"{Owner.GetActorLabel()} {Name.ToString()}")
				.Value("RecordedTransforms Num", RecordedTransforms.Num())
				.Value("RecordedTransforms RelativeTransform", RecordedTransforms.Last().RelativeTransform)
				.Value("RecordedTransforms Time", RecordedTransforms.Last().Time)
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(!ShouldRecord())
			return;

		BindEvents();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(!ShouldRecord())
			return;

		UnbindEvents();
	}

	private void BindEvents()
	{
		check(ShouldRecord());

		if(bBoundEvents)
			return;

		auto PredictionManager = Pinball::Prediction::GetManager();
		if(PredictionManager != nullptr)
		{
			PredictionManager.PerformRollback.AddUFunction(this, n"PerformRollback");
			PredictionManager.PreSubTick.AddUFunction(this, n"PreSubTick");
			PredictionManager.PreFinalize.AddUFunction(this, n"PreFinalize");
			bBoundEvents = true;
		} 
	}

	private void UnbindEvents()
	{
		if(!bBoundEvents)
			return;

		auto PredictionManager = Pinball::Prediction::GetManager();
		if(PredictionManager != nullptr)
		{
			PredictionManager.PerformRollback.Unbind(this, n"PerformRollback");
			PredictionManager.PreSubTick.Unbind(this, n"PreSubTick");
			PredictionManager.PreFinalize.Unbind(this, n"PreFinalize");
			bBoundEvents = false;
		}
	}

	UFUNCTION()
	private void PerformRollback(uint FrameNumber, float PredictionTime)
	{
		bIsPredicting = true;

		if(bPlaybackInPrediction)
			PrepareInitialTransform(PredictionTime);

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(f"PerformRollback", 1);
			const FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
			TemporalLog.Value("Time", PredictionTime);
		}
#endif

#if EDITOR
		while(RecordedTransforms.Num() > EditorMaxRecordings)
		{
			RecordedTransforms.RemoveAt(0);
		}
#else
		while(RecordedTransforms.Num() > 1 && RecordedTransforms[1].Time < PredictionTime)
		{
			// This sample is too old, remove
			// FB TODO: It would be way faster if we had a rolling buffer instead, but that's more complicated to implement
			RecordedTransforms.RemoveAt(0);
		}
#endif
	}

	UFUNCTION()
	private void PreSubTick(uint FrameNumber, uint SubframeNumber, float PredictionTime, float DeltaTime)
	{
		if(bPlaybackInPrediction)
		{
			PlaybackTransformAtTime(PredictionTime);
		}

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section(f"PreSubTick [{SubframeNumber}]", 2);
			const FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
			TemporalLog.Value("Time", PredictionTime);
		}
#endif

		OnSubTick.Broadcast(FrameNumber, SubframeNumber, PredictionTime);
	}

	UFUNCTION()
	private void PreFinalize(float InPredictionTime)
	{
#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("ResetTransformToCurrent", 3).Section("Before");
			FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
		}
#endif

		if(bPlaybackInPrediction)
			ResetTransformToCurrent();

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("ResetTransformToCurrent", 3).Section("After");
			FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
		}
#endif

		bIsPredicting = false;
	}

	// Prepare all components that influence movement so that they know where to reset to
	// This also places them at the initial location
	void PrepareInitialTransform(float PredictionInitialTime)
	{
		// First, cache where we were at the current time, so that we can return to here in PreFinalize
		InitialTransform = FPinballPredictionRecordedTransform(this, Time::OtherSideCrumbTrailSendTimePrediction);

		if(RecordedTransforms.IsEmpty())
			return;

		const FPinballPredictionRecordedTransform Transform = GetTransformAtTime(PredictionInitialTime);
		AttachParent.SetRelativeTransform(Transform.RelativeTransform);
	}

	// Move all components that influence the movement to where they should be
	void PlaybackTransformAtTime(float PredictionTime)
	{
		if(RecordedTransforms.IsEmpty())
			return;

		float Time = PredictionTime;
		if(bRemoveHalfPing)
			Time -= Network::PingOneWaySeconds;

		const FPinballPredictionRecordedTransform Transform = GetTransformAtTime(PredictionTime);
		AttachParent.SetRelativeTransform(Transform.RelativeTransform);
	}

	// PreFinalize
	// Reset all components to where they initially where
	// Do this before Finalize, so that ground following should put us where we should end up,
	// because the recorded transform in the last prediction tick will be one DeltaTime before the end.
	void ResetTransformToCurrent()
	{
#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("ResetTransformToCurrent", 3).Section("Before");
			FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
		}
#endif

		AttachParent.SetRelativeTransform(InitialTransform.RelativeTransform);

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("ResetTransformToCurrent", 3).Section("After");
			FBox BoundingBox = AttachParent.GetLocalBoundingBoxOfChildren(true, true, false);
			TemporalLog.Box("Bounds", AttachParent.WorldTransform.TransformPosition(BoundingBox.Center), BoundingBox.Extent * AttachParent.WorldScale, AttachParent.WorldRotation, FLinearColor::Red, 5);
			TemporalLog.Transform("Transform", AttachParent.WorldTransform, 500, 10);
		}
#endif
	}

	private FPinballPredictionRecordedTransform GetTransformAtTime(float Time) const
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictionRecordTransformComponent_GetTransformAtTime);

		if(!ensure(!RecordedTransforms.IsEmpty()))
			return FPinballPredictionRecordedTransform(this, Time::OtherSideCrumbTrailSendTimePrediction);

		const FPinballPredictionRecordedTransform LastRecordedTransform = RecordedTransforms.Last();
		if(Time >= LastRecordedTransform.Time)
			return LastRecordedTransform;

		const FPinballPredictionRecordedTransform FirstRecordedTransform = RecordedTransforms[0];
		if(Time <= FirstRecordedTransform.Time)
		{
			return FirstRecordedTransform;
		}

		FPinballPredictionRecordedTransform Previous;
		FPinballPredictionRecordedTransform Next;
		BinarySearchClosestPair(Time, Previous, Next);
		return Lerp(Previous, Next, Time);
	}

	private bool BinarySearchClosestPair(float Time, FPinballPredictionRecordedTransform&out Previous, FPinballPredictionRecordedTransform&out Next) const
	{
		if(!ensure(RecordedTransforms.Num() >= 2))
			return false;

		int Low = 0;
		int High = RecordedTransforms.Num() - 1;
		int Middle = 0;

		while(Low < High)
		{
			Middle = Math::IntegerDivisionTrunc(Low + High, 2);

			if(Time < RecordedTransforms[Middle].Time)
			{
				if(Middle > 0 && Time > RecordedTransforms[Middle - 1].Time)
				{
					Previous = RecordedTransforms[Middle - 1];
					Next = RecordedTransforms[Middle];
					return true;
				}

				High = Middle;
			}
			else
			{
				if(Middle < RecordedTransforms.Num() - 1 && Time < RecordedTransforms[Middle + 1].Time)
				{
					Previous = RecordedTransforms[Middle];
					Next = RecordedTransforms[Middle + 1];
					return true;
				}

				Low = Middle + 1;
			}
		}

		devError("Failed to find a valid pair!");
		return false;
	}

	private FPinballPredictionRecordedTransform Lerp(const FPinballPredictionRecordedTransform A, const FPinballPredictionRecordedTransform B, float Time) const
	{
		check(A.Time <= Time && Time <= B.Time);

		const float Alpha = Math::GetPercentageBetween(A.Time, B.Time, Time);
		check(Alpha >= 0 && Alpha <= 1);
		
		FPinballPredictionRecordedTransform Out;
		Out.RelativeTransform.Location = Math::Lerp(A.RelativeTransform.Location, B.RelativeTransform.Location, Alpha);
		Out.RelativeTransform.Rotation = FQuat::Slerp(A.RelativeTransform.Rotation, B.RelativeTransform.Rotation, Alpha);
		Out.RelativeTransform.Scale3D = Math::Lerp(A.RelativeTransform.Scale3D, B.RelativeTransform.Scale3D, Alpha);
		Out.Time = Time;
		return Out;
	}
};