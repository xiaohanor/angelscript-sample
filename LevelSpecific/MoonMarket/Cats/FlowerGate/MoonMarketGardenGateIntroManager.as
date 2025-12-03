event void FOnStartGardenGateIntro(AHazePlayerCharacter MainPlayer, bool bPlayBoth);

class AMoonMarketGardenGateIntroManager : AHazeActor
{
	UPROPERTY()
	FOnStartGardenGateIntro OnStartGardenGateIntro;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(3));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCompInner;
	default BoxCompInner.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxCompInner.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCompOuter;
	default BoxCompOuter.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxCompOuter.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UPROPERTY(EditAnywhere)
	AActor CatToDisable;

	TArray<AHazePlayerCharacter> PlayersForCutscene;

	bool bHavePlayed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
		
		if (!HasControl())
			return;

		BoxCompOuter.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoxCompOuter.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		BoxCompInner.OnComponentBeginOverlap.AddUFunction(this, n"OnInnerComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("PlayersForCutscene: " + PlayersForCutscene.Num());
	}

	//OUTER
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
	
		if (Player == nullptr)
			return;
		
		CrumbAddToCutscenes(Player);
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		CrumbRemoveFromtCutscenes(Player);
	}
	
	//INNER
	UFUNCTION()
	private void OnInnerComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                          UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                          bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		CrumbPlayCutscene(Player);
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		AddActorDisable(this);
		CatToDisable.AddActorDisable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddToCutscenes(AHazePlayerCharacter Player)
	{
		PlayersForCutscene.AddUnique(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveFromtCutscenes(AHazePlayerCharacter Player)
	{
		PlayersForCutscene.Remove(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayCutscene(AHazePlayerCharacter Player)
	{
		if (bHavePlayed)
			return;

		bHavePlayed = true;
		OnStartGardenGateIntro.Broadcast(Player, PlayersForCutscene.Num() > 1);
	}
};