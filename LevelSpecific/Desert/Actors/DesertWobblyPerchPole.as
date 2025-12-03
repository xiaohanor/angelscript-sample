UCLASS(Abstract)
class ADesertWobblyPerchPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsConeRotateComponent WobbleRoot;

	UPROPERTY(DefaultComponent, Attach = WobbleRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterComp;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UStaticMeshComponent PoleMeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartPerching");
	}

	UFUNCTION()
	private void StartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		WobbleRoot.ApplyImpulse(Player.ActorLocation, Player.ActorForwardVector * 100.0);
	}
}