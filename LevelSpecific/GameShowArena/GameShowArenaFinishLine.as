event void FOnBothPlayersReachedFinishline();

class AGameShowArenaFinishLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent FinishLineCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY()
	FOnBothPlayersReachedFinishline OnBothPlayersReachedFinishline; 

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = true;

	UPROPERTY(EditInstanceOnly)
	bool bShouldDisableAfterTrigger = true;	

	FInstigator StartDisabled;
	FInstigator DisableAfterTrigger;

	TArray<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bStartDisabled)
			AddActorDisable(StartDisabled);

		FinishLineCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnFinishLineOverlap");
		FinishLineCollision.OnComponentEndOverlap.AddUFunction(this, n"OnFinishLineEndOverlap");
	}

	UFUNCTION()
	private void OnFinishLineOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                 const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Players.AddUnique(Player);

		if(Players.Num() == 2)
			OnBothPlayersReachedFinishline.Broadcast();
		else
			return;

		if(bShouldDisableAfterTrigger)
			AddActorDisable(DisableAfterTrigger);
	}
	
	UFUNCTION()
	private void OnFinishLineEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Players.Remove(Player);
	}
}