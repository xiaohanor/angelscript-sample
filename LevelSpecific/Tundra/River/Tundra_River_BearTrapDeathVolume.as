class ATundra_River_BearTrapDeathVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerBoxComp;
	default TriggerBoxComp.BoxExtent = FVector(100, 100, 100);
	default TriggerBoxComp.ShapeColor = FColor::Orange;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		TriggerBoxComp.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		auto BearTrapPlayerComp = UTundra_River_BearTrapTriggerPlayerComponent::Get(Player);
		if(BearTrapPlayerComp != nullptr)
		{
			BearTrapPlayerComp.AddVolume(this);
		}

	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		auto BearTrapPlayerComp = UTundra_River_BearTrapTriggerPlayerComponent::Get(Player);
		if(BearTrapPlayerComp != nullptr)
		{
			BearTrapPlayerComp.RemoveVolume(this);
		}
	}
};