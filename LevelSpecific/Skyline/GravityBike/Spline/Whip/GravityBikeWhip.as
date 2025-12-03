UCLASS(Abstract)
class AGravityBikeWhip : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Zoe;
	}
}

namespace GravityBikeWhip
{
	UFUNCTION(BlueprintPure)
	AGravityBikeWhip GetGravityBikeWhip()
	{
		return UGravityBikeWhipComponent::Get(Game::Zoe).GetOrCreateWhipActor();
	}
}