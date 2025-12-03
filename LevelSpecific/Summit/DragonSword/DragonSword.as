UCLASS(Abstract)
class ADragonSword : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	UStaticMeshComponent SwordMesh;
	default SwordMesh.bGenerateOverlapEvents = false;
	default SwordMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default SwordMesh.CollisionProfileName = n"NoCollision";
	default SwordMesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	AHazePlayerCharacter Player;
};