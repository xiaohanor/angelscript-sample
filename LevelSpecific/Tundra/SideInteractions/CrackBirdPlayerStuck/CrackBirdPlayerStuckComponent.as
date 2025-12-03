UCLASS(NotBlueprintable)
class UCrackBirdPlayerStuckComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	ABigCrackBird StuckInBird;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbBecomeStuckInBird(ABigCrackBird Bird)
	{
		StuckInBird = Bird;
		StuckInBird.OnPlayerBecomeStuck(Player);
	}

	bool IsStuckInBird() const
	{
		return IsValid(StuckInBird);
	}

	void ExplodeBird()
	{
		if(StuckInBird == nullptr)
			return;

		StuckInBird.Explode();
		StuckInBird = nullptr;
	}
};