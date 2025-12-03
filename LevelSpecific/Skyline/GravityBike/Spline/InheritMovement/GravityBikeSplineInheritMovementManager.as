UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeSplineInheritMovementManager : UActorComponent
{
	TArray<UGravityBikeSplineInheritMovementComponent> EnterZones;
};

namespace GravityBikeSpline
{
	UGravityBikeSplineInheritMovementManager GetInheritMovementManager()
	{
		return UGravityBikeSplineInheritMovementManager::GetOrCreate(GravityBikeSpline::GetDriverPlayer());
	}
}