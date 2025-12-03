class AForgePipeInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Icon;
	default Icon.SetWorldScale3D(FVector(5.0));

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal Metal;

	UPROPERTY(EditAnywhere, Category = "Setup")
	APropLine PropLine;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bAtStart = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	//default InteractComp.InteractionCapability = n"ForgePipeTravelCapability";


	
	UHazeSplineComponent SplineComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		

		SplineComp = Spline::GetGameplaySpline(PropLine, this);
		if(Metal == nullptr)
			return;
		
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		InteractComp.Disable(this);
	}


	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		InteractComp.Disable(this);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		InteractComp.Enable(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
	// 	if(OtherPipe == nullptr)
	// 		return;
		
	// 	UPlayerTailTeenDragonComponent DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
	// 	DragonComp.TeenDragon.ActorLocation = OtherPipe.InteractComp.WorldLocation;
	}
}