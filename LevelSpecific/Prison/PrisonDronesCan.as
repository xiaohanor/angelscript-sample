UCLASS(Abstract)
class APrisonDronesCan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComp;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazePlayerCharacter Player)
	{
		FVector Impulse = Player.GetActorLocation() - GetActorLocation();
		Impulse.Z = 10000;
		MeshComp.AddImpulseAtLocation(Player.GetActorLocation() - GetActorLocation(),Player.GetActorLocation());
	}
};
