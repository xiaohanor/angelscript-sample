UCLASS(Abstract)
class AEvergreenRockMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bTickInEditor = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditInstanceOnly)
	AMovingVine MovingVineRef;

	UPROPERTY(EditInstanceOnly)
	FTransform Stem1Transform = FTransform::Identity;

	FTransform GetStem5Transform() const property
	{
		if (!IsValid(MovingVineRef))
			return FTransform::Identity;

		FTransform Transform = FTransform::Identity;
		Transform.Location = ActorTransform.InverseTransformPosition(MovingVineRef.ActorLocation);
		Transform.Rotation = ActorTransform.InverseTransformRotation(MovingVineRef.ActorQuat);
		return Transform;
	}

	UBoxComponent GetCollision() const
	{
		return UBoxComponent::Get(this);
	}

	FVector GetEscapeDirection() const property
	{
		UBoxComponent Collision = GetCollision();
		if (Collision == nullptr)
			return FVector(-1.0, 0.0, 0.0);
		return -Collision.WorldRotation.RightVector;
	}

	FVector GetCollisionCenter() const property
	{
		UBoxComponent Collision = GetCollision();
		if (Collision == nullptr)
			return ActorLocation;
		return Collision.WorldLocation;
	}
}