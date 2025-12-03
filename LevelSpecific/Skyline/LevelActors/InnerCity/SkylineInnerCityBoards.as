UCLASS(Abstract)
class ASkylineInnerCityBoards : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PlankMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchPoint;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	FVector LaunchImpulse;
	float LaunchSpeed = 300000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandleEnter");
		LaunchImpulse = LaunchPoint.UpVector * LaunchSpeed;
		UHazeMovementComponent MoveCompMio = UHazeMovementComponent::Get(Game::Mio);
		UHazeMovementComponent MoveCompZoe = UHazeMovementComponent::Get(Game::Zoe);
		MoveCompMio.AddMovementIgnoresActor(this, this);
		MoveCompZoe.AddMovementIgnoresActor(this, this);
	}

	UFUNCTION()
	private void HandleEnter(AHazePlayerCharacter Player)
	{
		PlankMesh.SetSimulatePhysics(true);
		PlankMesh.AddImpulse(LaunchImpulse);
		HandleEnterBP();
	}
	

	UFUNCTION(BlueprintEvent)
	void HandleEnterBP()
	{

	}
};
