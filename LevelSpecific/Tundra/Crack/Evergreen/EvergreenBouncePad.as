UCLASS(Abstract)
class AEvergreenBouncePad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshScaleRoot;

	UPROPERTY(DefaultComponent, Attach = MeshScaleRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBoxComponent BounceTrigger;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	AHazePlayerCharacter Player;

	float BounceVelocity = 2500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BounceTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{

		Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;	
		
		TriggerBounceFX();
		Timer::SetTimer(this, n"GiveVelocity", 0.1);

	}

	UFUNCTION()
	void GiveVelocity()
	{
		Player.SetActorVerticalVelocity(FVector(0.0, 0.0, BounceVelocity));
	}

	UFUNCTION(BlueprintEvent)
	void TriggerBounceFX() {}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector NewDirection = FVector(Manager.LifeComp.RawHorizontalInput, 0, Manager.LifeComp.RawVerticalInput);
		NewDirection *= 20;
		AddActorLocalOffset(NewDirection);
	}
}