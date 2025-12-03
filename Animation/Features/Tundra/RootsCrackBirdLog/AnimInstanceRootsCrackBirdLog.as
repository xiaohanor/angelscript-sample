UCLASS(Abstract)
class UAnimInstanceRootsCrackBirdLog : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform TipTransform;

	ATundraCrackSpringLog SpringLog;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		SpringLog = Cast<ATundraCrackSpringLog>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(SpringLog == nullptr)
			SpringLog = Cast<ATundraCrackSpringLog>(OwningComponent.Owner);

		if(SpringLog == nullptr)
			return;

		FTransform Transform = FTransform::Identity;
		FVector LocalOffset = SpringLog.ActorTransform.InverseTransformPosition(SpringLog.LogicalMeshTransform.TransformPosition(SpringLog.RootsAttachPivotLocation)) + SpringLog.RootsRelativeRootOffset - SpringLog.RootsAttachPivotLocation;
		FRotator LocalRotation = SpringLog.ActorTransform.InverseTransformRotation(SpringLog.Mesh.WorldRotation) + SpringLog.RootsRelativeRotationOffsets;

		Transform.Location = FVector(LocalOffset.Y, -LocalOffset.X, -LocalOffset.Z);
		Transform.Rotation = FRotator(-LocalRotation.Pitch, -LocalRotation.Yaw, -LocalRotation.Roll).Quaternion();
		TipTransform = Transform;
	}
}