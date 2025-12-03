class ASkylineInnerCitySlideOffCarVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	bool bShouldTriggerEnter = false;
	
	UPROPERTY(DefaultComponent)
	UBoxComponent BoxTrigger;
	
	default BoxTrigger.bGenerateOverlapEvents = true;
	default BoxTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		BoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
		InterfaceComp.OnActivated.AddUFunction(this, n"HanldeOnActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleOnDeactivated");
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if(Player.IsOnWalkableGround())
			Player.ApplyKnockdown((BoxTrigger.RightVector * 1800) + FVector::UpVector * 1000, 4.0);

		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 0.0, this);

		

		//PrintToScreenScaled("ENTER", 5.0, FLinearColor::Black, 10.0);
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);

		//PrintToScreenScaled("LEAVE", 5.0, FLinearColor::Red, 10.0);
	}

	UFUNCTION()
	private void HandleOnDeactivated(AActor Caller)
	{
		BoxTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void HanldeOnActivated(AActor Caller)
	{
		BoxTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	
	}


};