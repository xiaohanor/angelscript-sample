event void FSanctuarySmoothMovingComponentSignature();

class USanctuarySmoothMovingComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Speed = 1000.0;

	UPROPERTY(EditAnywhere)
	float LerpSpeed = 2.0;

	float Margin = 1.0;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FTransform TargetTransform;

	FTransform InitialRelativeTransform;

	FTransform LerpTargetTransform;
	FVector Velocity;

	FSanctuarySmoothMovingComponentSignature OnTargetReached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeTransform = RelativeTransform;
		TargetTransform = InitialRelativeTransform;
		LerpTargetTransform = InitialRelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector ToTarget = TargetTransform.Location - LerpTargetTransform.Location;
		float DistanceToTarget = ToTarget.Size();
		FVector DeltaMove = ToTarget.SafeNormal * Math::Min(DistanceToTarget, Speed * DeltaSeconds);

		LerpTargetTransform.Location = LerpTargetTransform.Location + DeltaMove;

		RelativeTransform = LerpTransform(RelativeTransform, LerpTargetTransform, LerpSpeed * DeltaSeconds);

//		Debug::DrawDebugPoint(LerpTargetTransform.Location, 50.0, FLinearColor::Red, 0.0);
//		Debug::DrawDebugPoint(RelativeTransform.Location, 50.0, FLinearColor::Green, 0.0);

		if (DistanceToTarget < Margin)
		{
			OnTargetReached.Broadcast();
		}
	}

	UFUNCTION()
	void SetRelativeTransformTarget(FTransform Target)
	{
		TargetTransform = Target * InitialRelativeTransform; // * Target;
	}

	UFUNCTION()
	void SetWorldTransformTarget(FTransform Target)
	{
		TargetTransform = Target;
	}	

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		Transform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		Transform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		
		return Transform;
	}
};