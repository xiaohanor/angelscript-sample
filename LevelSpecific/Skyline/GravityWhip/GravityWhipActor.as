UCLASS(Abstract)
class AGravityWhipActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default Mesh.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bGenerateOverlapEvents = false;

	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeMovementAudioComponent MoveAudioComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Zoe;
	}
}