/**
 * Purely visual, since we can't use the blade during the GravityBikeFree level
 */
UCLASS(Abstract)
class AGravityBikeFreeBlade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UHazeSkeletalMeshComponentBase BladeMeshComp;
	default BladeMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif
};

namespace GravityBikeFreeBlade
{
	UFUNCTION(BlueprintPure)
	AGravityBikeFreeBlade GetGravityBikeFreeBlade()
	{
		return UGravityBikeFreeBladePlayerComponent::Get(Game::Mio).GetOrCreateBladeActor();
	}
}