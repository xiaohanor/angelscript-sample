event void FPigSwivelPadEvent();

UCLASS(Abstract)
class APigSwivelPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent SwivelRoot;

	UPROPERTY(DefaultComponent, Attach = SwivelRoot)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY()
	FPigSwivelPadEvent OnSwivelHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		SwivelRoot.ApplyAngularImpulse(6.0);

		OnSwivelHit.Broadcast();
	}
}