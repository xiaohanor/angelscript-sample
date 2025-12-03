UCLASS(Abstract)
class AExplosiveSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SwingPointRoot;

	UPROPERTY(DefaultComponent, Attach = SwingPointRoot)
	USwingPointComponent SwingPointComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"PlayerAttached");
	}

	UFUNCTION()
	private void PlayerAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		FExplosiveSwingPointParams Params;
		Params.Player = Player;
		UExplosiveSwingPointEffectEventHandler::Trigger_PlayerKilled(this, Params);

		BP_PlayerAttached(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayerAttached(AHazePlayerCharacter Player) {}
}