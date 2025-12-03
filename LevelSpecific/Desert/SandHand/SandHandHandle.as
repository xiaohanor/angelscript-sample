class ASandHandHandle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HandleAttachment;

	UPROPERTY(DefaultComponent, Attach = HandleAttachment)
	UStaticMeshComponent HolderMeshComp;
	default HolderMeshComp.RelativeRotation = FRotator(0.0, 90.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = HandleAttachment)
	UFauxPhysicsAxisRotateComponent HandleRotateRoot;
	default HandleRotateRoot.Friction = 3.0;
	default HandleRotateRoot.ForceScalar = 1.0;
	default HandleRotateRoot.LocalRotationAxis = FVector(0.0, 1.0, 0.0);
	default HandleRotateRoot.SpringStrength = 8.0;
	default HandleRotateRoot.bConstrain = true;
	default HandleRotateRoot.ConstrainAngleMin = -180.0;
	default HandleRotateRoot.ConstrainBounce = 0.0;

	UPROPERTY(DefaultComponent, Attach = HandleRotateRoot)
	UStaticMeshComponent HandleMeshComp;
	default HandleMeshComp.RelativeRotation = FRotator(0.0, 90.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = HandleRotateRoot)
	USceneComponent TargetingRoot;
}