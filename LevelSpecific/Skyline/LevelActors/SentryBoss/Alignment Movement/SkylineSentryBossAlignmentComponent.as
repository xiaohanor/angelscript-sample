class USkylineSentryBossAlignmentComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float Speed = 300.0;

	UPROPERTY(EditAnywhere)
	float Drag = 6.0;

	UPROPERTY(EditAnywhere)
	bool bIsHoming = true;

	bool bIsMoving = true;
	
	FVector Velocity;


	FTransform GetAlignment(FTransform Source)
	{
		FTransform Transform;

		FVector SourceToOwner = Owner.ActorLocation - Source.Location;

		Transform.Location = Owner.ActorLocation;
		Transform.Rotation = FQuat::MakeFromZX(SourceToOwner.SafeNormal, Source.Rotation.UpVector);
		Transform.Scale3D = Owner.ActorScale3D;

		return Transform;
	}
}