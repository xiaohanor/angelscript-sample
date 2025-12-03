UCLASS(Abstract)
class AIslandRiftIntroElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION()
	void JiggleCollision()
	{
		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);
	}
};
