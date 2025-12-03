class ASkylineSubwayForceField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent CollisonComp;
	default CollisonComp.bGenerateOverlapEvents = false;
	default CollisonComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CollisonComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		CollisonComp.CollisionEnabled = ECollisionEnabled::NoCollision;
		BP_Activated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}
};