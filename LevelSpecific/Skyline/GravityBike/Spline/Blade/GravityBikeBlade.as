UCLASS(Abstract)
class AGravityBikeBlade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UHazeSkeletalMeshComponentBase BladeMeshComp;
	default BladeMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif
};

namespace GravityBikeBlade
{
	UFUNCTION(BlueprintPure)
	AGravityBikeBlade GetGravityBikeBlade()
	{
		return UGravityBikeBladePlayerComponent::Get(GetPlayer()).GetOrCreateBladeActor();
	}
}