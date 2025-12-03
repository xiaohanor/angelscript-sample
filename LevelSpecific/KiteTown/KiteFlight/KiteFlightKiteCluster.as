UCLASS(Abstract)
class AKiteFlightKiteCluster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ClusterRoot;

	UPROPERTY(DefaultComponent, Attach = ClusterRoot)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		UKiteFlightPlayerComponent KiteFlightComp = UKiteFlightPlayerComponent::Get(Player);
		KiteFlightComp.ActivateFlight();
	}
}