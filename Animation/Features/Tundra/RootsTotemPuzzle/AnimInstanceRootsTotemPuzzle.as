UCLASS(Abstract)
class UAnimInstanceRootsTotemPuzzle : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform TipTransform;

	ATundra_River_TotemPuzzle_MovingRoot TotemPuzzle;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		TotemPuzzle = Cast<ATundra_River_TotemPuzzle_MovingRoot>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(TotemPuzzle == nullptr)
			TotemPuzzle = Cast<ATundra_River_TotemPuzzle_MovingRoot>(OwningComponent.Owner);

		if(TotemPuzzle == nullptr)
			return;

		FTransform Transform = FTransform::Identity;
		FVector LocalOffset = TotemPuzzle.MovingRoot.RelativeLocation + TotemPuzzle.CurrentLocalRootTipLocation;
		FRotator LocalRotation = TotemPuzzle.CurrentLocalRootTipRotation;

#if EDITOR
		if(!Editor::IsPlaying())
		{
			if(TotemPuzzle.bPreviewTargetInEditor)
			{
				LocalOffset = TotemPuzzle.MovingRoot.RelativeLocation + TotemPuzzle.LocalRootTipHitTargetLocation;
				LocalRotation = TotemPuzzle.LocalRootTipHitTargetRotation;
			}
			else
			{
				LocalOffset = TotemPuzzle.MovingRoot.RelativeLocation + TotemPuzzle.LocalRootTipDefaultLocation;
				LocalRotation = TotemPuzzle.LocalRootTipDefaultRotation;
			}
		}
#endif

		Transform.Location = FVector(LocalOffset.Z, -LocalOffset.Y, LocalOffset.X);
		Transform.Rotation = FRotator(-LocalRotation.Pitch, -LocalRotation.Roll, -LocalRotation.Yaw).Quaternion();
		TipTransform = Transform;
	}
}