UCLASS(Abstract)
class AStaticAnimatingPig : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.RelativeLocation = FVector(50.0, 0.0, 55.0);
	default CollisionComp.RelativeRotation = FRotator(-90.0, 0.0, 0.0);
	default CollisionComp.CapsuleHalfHeight = 100.0;
	default CollisionComp.CapsuleRadius = 55.0;
	default CollisionComp.bGenerateOverlapEvents = false;
	default CollisionComp.CollisionProfileName = CollisionProfile::BlockAll;
	default CollisionComp.RemoveTag(ComponentTags::Walkable);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;
}