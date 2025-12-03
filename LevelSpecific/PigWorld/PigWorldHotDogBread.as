event void BothHotdogsReady();
event void HotdogReady(AHazePlayerCharacter Player);
event void FBunsTalkingVO();

UCLASS(Abstract)
class APigWorldHotDogBread : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent CharacterTemplateComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapabilityClass.Set(UPigSausageBunInteractionCapability);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BreadTopRoot;

	UPROPERTY(DefaultComponent, Attach = BreadTopRoot)
	UStaticMeshComponent BreadTop;


	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BreadBottomRoot;
		
	UPROPERTY(DefaultComponent, Attach = BreadBottomRoot)	
	UStaticMeshComponent BreadBottom;


	//collision
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BreadTopCollision;
	default BreadTopCollision.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)	
	UStaticMeshComponent BreadBottomCollision;
	default BreadBottomCollision.bHiddenInGame = true;


	UPlayerPigSausageComponent SausageComp;

	UPROPERTY(DefaultComponent,Attach = Root)
	UBillboardComponent LaunchToLocation;

	UPROPERTY()
	BothHotdogsReady OnBothHotdogsReady;

	UPROPERTY()
	HotdogReady OnHotdogReady;

	UPROPERTY(EditAnywhere)
	APigWorldHotDogBread OtherBread;
	
	UPROPERTY(EditAnywhere)
	bool bIsTalking;

	UPROPERTY(EditAnywhere)
	bool bIsReady;

	UPROPERTY(EditAnywhere)
	bool bIsInBread;

	UPROPERTY(EditAnywhere)
	bool bCutscene = false;

	UPROPERTY()
	AHazePlayerCharacter PlayerCharacter;
	
	UPROPERTY()
	FBunsTalkingVO HotDogNotGrilled;

	UPROPERTY()
	FBunsTalkingVO HotDogNotCondiments;

	UPROPERTY()
	FBunsTalkingVO HotDogNotKetchup;

	UPROPERTY()
	FBunsTalkingVO HotDogNotMustard;

	UPROPERTY()
	FBunsTalkingVO HotDogIsDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}
	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		SausageComp = UPlayerPigSausageComponent::Get(Player);

		bIsInBread = true;

		UPigSausageEventHandler::Trigger_LandEvent(this);

		if(!SausageComp.bIsGrilled)
		{
			NotGrilled();
			HotDogNotGrilled.Broadcast();
		}
		else if(!SausageComp.bIsKetchup && !SausageComp.bIsMustard)
		{
			NoCondiments();
			HotDogNotCondiments.Broadcast();
		}
			
		else if(!SausageComp.bIsKetchup)
		{	
			NoKetchup();
			HotDogNotKetchup.Broadcast();
		}
		else if(!SausageComp.bIsMustard)
		{
			NoMustard();
			HotDogNotMustard.Broadcast();
		}
			
		else
		 {
			HotdogDone();
			bIsReady = true;

			OnHotdogReady.Broadcast(Player);

			if(bIsReady && OtherBread.bIsReady)
			{
				if (Network::HasWorldControl())
					NetBothHotDogsReady();
			}
		 }
	}

	UFUNCTION(BlueprintCallable)
	void Voiceline(AHazePlayerCharacter Player)
	{	
		if(!(bIsReady && OtherBread.bIsReady) && bIsInBread)
		{
			OnInteractionStarted(InteractionComp, Player);
		}
	}

	UFUNCTION(NetFunction)
	private void NetBothHotDogsReady()
	{
		bCutscene = true;
		OtherBread.bCutscene = true;
		InteractionComp.bPlayerCanCancelInteraction = false;
		OtherBread.InteractionComp.bPlayerCanCancelInteraction = false;
		OnBothHotdogsReady.Broadcast();
		OtherBread.OnBothHotdogsReady.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void NotGrilled(){}

	UFUNCTION(BlueprintEvent)
	void NoCondiments(){}

	UFUNCTION(BlueprintEvent)
	void NoKetchup(){}

	UFUNCTION(BlueprintEvent)
	void NoMustard(){}

	UFUNCTION(BlueprintEvent)
	void HotdogDone(){}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsReady = false;
		bIsInBread = false;
		UPigSausageEventHandler::Trigger_JumpEvent(this);
	}
};
