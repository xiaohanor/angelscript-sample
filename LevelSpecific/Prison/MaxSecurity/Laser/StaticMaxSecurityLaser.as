/**
 * A static laser which does no traces or movement.
 * Intended to be surrounded by a volume that kills the players.
 */
UCLASS(Abstract)
class AStaticMaxSecurityLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent LaserMeshComp;
	default LaserMeshComp.Mobility = EComponentMobility::Static;
	default LaserMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default LaserMeshComp.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.Mobility = EComponentMobility::Static;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp.bGenerateOverlapEvents = false;

	UPROPERTY(EditAnywhere)
	bool bShowEmitter = true;

	UPROPERTY(EditAnywhere)
	float LaserLength = 1000.0;

	UPROPERTY(EditAnywhere)
	float LaserWidth = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LaserMeshComp.SetRelativeScale3D(FVector(LaserLength, LaserWidth, LaserWidth));

		if (bShowEmitter)
			MeshComp.SetVisibility(true);
		else
			MeshComp.SetVisibility(false);
	}

	#if EDITOR
	/** Convert a regular laser to a static version */
	void CopyFrom(AMaxSecurityLaser Other)
	{
		SetActorTransform(Other.ActorTransform);

		if(Other.AttachParentActor != nullptr)
			AttachToActor(Other.AttachParentActor, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		LaserMeshComp.SetRelativeLocation(Other.LaserMeshComp.RelativeLocation);
		LaserMeshComp.SetRelativeScale3D(FVector(Other.LaserComp.BeamLength, Other.LaserComp.BeamWidth, Other.LaserComp.BeamWidth));

		MeshComp.SetRelativeTransform(Other.MeshComp.RelativeTransform);
		LaserMeshComp.SetRelativeTransform(Other.LaserMeshComp.RelativeTransform);
	}
	#endif
};