event void FGravityBikeSplineOnPlayerMounted(AGravityBikeSpline GravityBike);

struct FGravityBikeSplinePlayerAnimationData
{
    bool bIsPassenger;
}

UCLASS(Abstract)
class UGravityBikeSplinePlayerComponent : UActorComponent
{
	access Protected = protected, AGravityBikeSpline (inherited);

	UPROPERTY()
	FGravityBikeSplineOnPlayerMounted OnPlayerMounted;

    FGravityBikeSplinePlayerAnimationData AnimationData;

	AHazePlayerCharacter Player;
	AGravityBikeSpline GravityBike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsPassenger() const
	{
		return false;
	}
};