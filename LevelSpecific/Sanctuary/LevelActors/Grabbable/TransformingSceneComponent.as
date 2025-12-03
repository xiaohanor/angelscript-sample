event void FTransformingSceneComponentSignature();

class UTransformingSceneComponent : USceneComponent
{
	FTransform InitialTransform;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FTransform PresetTargetTransform;

	FTransform CurrentTargetTransform;

	USceneComponent TargetRelativeToComponent;

	float TimeStamp = -1.0;

	bool bTransformComplete = true;

	UPROPERTY(EditAnywhere)
	float TransformDuration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bSpringTo = false;

	UPROPERTY(EditAnywhere)
	float SpringStiffness = 8.0;

	UPROPERTY(EditAnywhere)
	float SpringDamping = 0.5;

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedRotation;
	FHazeAcceleratedVector AcceleratedScale;

	UPROPERTY()
	FTransformingSceneComponentSignature OnTransformComplete;

	UPROPERTY()
	FTransformingSceneComponentSignature OnTransformBegin;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialTransform = RelativeTransform;
		AcceleratedScale.SnapTo(InitialTransform.Scale3D);

		CurrentTargetTransform = PresetTargetTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bSpringTo)
			SpringToTransform(TargetTransform, TransformDuration, DeltaSeconds);
		else
			AccelerateToTransform(TargetTransform, TransformDuration, DeltaSeconds);

		RelativeTransform = CurrentTransform * InitialTransform;
	
		if (!bTransformComplete && Time::GameTimeSeconds > TimeStamp && TimeStamp > 0.0)
		{
			PrintToScreen("TimeStamp Complete", 0.0, FLinearColor::Yellow);
			bTransformComplete = true;
			OnTransformComplete.Broadcast();
		}

	/*
		if (RelativeTransform.Equals(TargetTransform * InitialTransform, 1.0) && !RelativeTransform.Equals(InitialTransform, 1.0))
		{
			PrintToScreen("Transform Complete", 0.0, FLinearColor::Green);
		}
	*/
	}

	UFUNCTION()
	void SetTargetTransform(FTransform Target = FTransform::Identity, USceneComponent RelativeToComponent = nullptr, bool bWorldSpace = false)
	{
		bTransformComplete = false;

		TimeStamp = Time::GameTimeSeconds + TransformDuration;

		TargetRelativeToComponent = RelativeToComponent;

		OnTransformBegin.Broadcast();

		if (TargetRelativeToComponent != nullptr)
		{
			CurrentTargetTransform = Target;
			return;
		}

		if (bWorldSpace)
		{
			CurrentTargetTransform = Target.GetRelativeTransform(WorldTransform);
			return;
		}

		CurrentTargetTransform = Target;
	}

	UFUNCTION()
	void Reset()
	{
		TimeStamp = -1.0;
		OnTransformBegin.Broadcast();
		bTransformComplete = false;
		CurrentTargetTransform = FTransform::Identity;
		TargetRelativeToComponent = nullptr;
	}

	FTransform GetTargetTransform() property
	{
		FTransform Transform = CurrentTargetTransform;

		if (TargetRelativeToComponent != nullptr)
		{
			Transform = (CurrentTargetTransform * TargetRelativeToComponent.WorldTransform).GetRelativeTransform(InitialTransform);
		}

		return Transform;
	}

	void AccelerateToTransform(FTransform Target, float Duration, float DeltaSeconds)
	{
		AcceleratedLocation.AccelerateTo(Target.Location, Duration, DeltaSeconds);
		AcceleratedRotation.AccelerateTo(Target.Rotation, Duration, DeltaSeconds);
		AcceleratedScale.AccelerateTo(Target.Scale3D, Duration, DeltaSeconds);
	}

	void SpringToTransform(FTransform Target, float Duration, float DeltaSeconds)
	{
		AcceleratedLocation.SpringTo(Target.Location, SpringStiffness, SpringDamping, DeltaSeconds);
		AcceleratedRotation.SpringTo(Target.Rotation, SpringStiffness, SpringDamping, DeltaSeconds);
		AcceleratedScale.SpringTo(Target.Scale3D, SpringStiffness, SpringDamping, DeltaSeconds);
	}

	void SnapToTransform(FTransform Target)
	{
		AcceleratedLocation.SnapTo(Target.Location);
		AcceleratedRotation.SnapTo(Target.Rotation);
		AcceleratedScale.SnapTo(Target.Scale3D);
	}

	FTransform GetCurrentTransform() property
	{
		FTransform Transform;
		Transform.Location = AcceleratedLocation.Value;
		Transform.Rotation = AcceleratedRotation.Value;
		Transform.Scale3D = AcceleratedScale.Value;

		return Transform;
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		Transform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		Transform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		
		return Transform;
	}
}