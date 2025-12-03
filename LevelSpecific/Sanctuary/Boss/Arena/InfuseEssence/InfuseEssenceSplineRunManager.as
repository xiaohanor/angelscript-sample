event void FSanctuarySplineRunOnReachedEnd();

class AInfuseEssenceSplineRunManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	/*
	UPROPERTY(EditAnywhere)
	AInfuseEssenceBothManager FirstEssenceInteractable;
	UPROPERTY(EditAnywhere)
	AInfuseEssenceBothManager SecondEssenceInteractable;
	UPROPERTY(EditAnywhere)
	AInfuseEssenceBothManager ThirdEssenceInteractable;
	UPROPERTY(EditAnywhere)
	AInfuseEssenceBothManager FourthEssenceInteractable;
	UPROPERTY(EditAnywhere)
	TArray<AInfuseEssenceBothManager> EssenceManagers;
	*/

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSplineRun Spline;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSplineRunPlatform EndPlatform;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere)
	AHazeTargetPoint TargetPoint;

	UPROPERTY(EditAnywhere)
	AHazeTargetPoint EndPhaseTargetPoint;

	bool bHasStopped = false;

	FSanctuarySplineRunOnReachedEnd OnSanctuarySplineRunOnReachedEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//FirstEssenceInteractable.InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleMioInfusedFirst");
		//SecondEssenceInteractable.InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleMioInfusedSecond");
		//ThirdEssenceInteractable.InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleMioInfusedThird");
		//FourthEssenceInteractable.InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleMioInfusedFourth");
		
	}

/*
	UFUNCTION()
	private void HandleMioInfusedFirst(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		FirstEssenceInteractable.bInteracted = true;
		//ChangeFirstPlatforms();
	}

	UFUNCTION()
	private void HandleMioInfusedSecond(UInteractionComponent InteractionComponent,
	                                 AHazePlayerCharacter Player)
	{
		SecondEssenceInteractable.bInteracted = true;
		//ChangeSecondPlatforms();	
	}

	UFUNCTION()
	private void HandleMioInfusedThird(UInteractionComponent InteractionComponent,
	                                   AHazePlayerCharacter Player)
	{
		ThirdEssenceInteractable.bInteracted = true;
	}

		UFUNCTION()
	private void HandleMioInfusedFourth(UInteractionComponent InteractionComponent,
	                                    AHazePlayerCharacter Player)
	{
		FourthEssenceInteractable.bInteracted = true;
	}*/


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		/*for(auto EssenceManager : EssenceManagers)
		{
			if(EssenceManager.bInteracted == true && EssenceManager.GetDistanceTo(TargetPoint) < 1500)
			{
				EssenceManager.RespawnEssence();
				EssenceManager.bInteracted = false;
			}
		}*/

		if(EndPlatform==nullptr)
		{
			return;
		}
		
		if(EndPlatform.GetDistanceTo(EndPhaseTargetPoint) < 500 && !bHasStopped)
		{
			bHasStopped = true;
			Spline.ActorTickEnabled = false;
			//HydraDissapear();
			OnSanctuarySplineRunOnReachedEnd.Broadcast();
		}
	}
};