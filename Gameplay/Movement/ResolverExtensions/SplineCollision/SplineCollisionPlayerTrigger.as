UCLASS(NotBlueprintable)
class ASplineCollisionPlayerTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> Splines;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ApplySplineCollision(Splines, this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ClearSplineCollision(this);
	}
}