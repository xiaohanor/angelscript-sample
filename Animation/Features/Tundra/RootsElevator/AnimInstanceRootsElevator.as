UCLASS(Abstract)
class UAnimInstanceRootsElevator : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform TipTransform;

	ATundra_River_RangedInteract_MovingMonkeyClimbActor ClimbActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		ClimbActor = Cast<ATundra_River_RangedInteract_MovingMonkeyClimbActor>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(ClimbActor == nullptr)
			ClimbActor = Cast<ATundra_River_RangedInteract_MovingMonkeyClimbActor>(OwningComponent.Owner);

		if(ClimbActor == nullptr)
			return;

		FTransform Transform = FTransform::Identity;
		Transform.Location = ClimbActor.BoneLocalLocationOffset + FVector::ForwardVector * (ClimbActor.ActorLocation - ClimbActor.MoveRoot.WorldLocation).Size();
		Transform.Rotation = ClimbActor.BoneLocalRotationOffset.Quaternion();
		TipTransform = Transform;
	}
}