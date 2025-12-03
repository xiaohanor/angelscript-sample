event void FOnPlayerEnteredFullScreenTrigger();

UCLASS(Abstract)
class ALiftSectionFullScreenTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerVolume;

	UPROPERTY()
	FOnPlayerEnteredFullScreenTrigger OnPlayerEnteredFullScreenTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerVolume.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapActionArea");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime){}

	UFUNCTION()
    private void BeginOverlapActionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (Player == Game::GetMio())
			return;

		OnPlayerEnteredFullScreenTrigger.Broadcast();
    }
}