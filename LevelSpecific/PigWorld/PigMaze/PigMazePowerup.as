class APigMazePowerup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PowerupRootComp;

	UPROPERTY(DefaultComponent, Attach = PowerupRootComp)
	UCapsuleComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	bool bPickedUp = false;
	
	AHazePlayerCharacter AffectedPlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bPickedUp)
			return;

		bPickedUp = true;

		BP_PickedUp();

		AddActorDisable(this);

		AffectedPlayer = Player;
		UPigMazePowerupPlayerComponent PlayerComp = UPigMazePowerupPlayerComponent::GetOrCreate(Player);
		PlayerComp.ActivatePowerup();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PickedUp() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PowerupRootComp.AddLocalRotation(FRotator(0.0, 360.0 * DeltaTime, 0.0));
	}
}