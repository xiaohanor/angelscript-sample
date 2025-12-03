class AIslandPrototypeWalkerAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent Collision;

	bool bMioOn;
	bool bZoeOn;
	bool bIsCompleted;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 0.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = 3.0;
	default DelayAnimation.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		DelayAnimation.BindFinished(this, n"OnDelayFinished");
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		

	}

	UFUNCTION()
	void OnFinished()
	{
		
	}

	UFUNCTION()
	void OnDelayFinished()
	{
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bIsCompleted)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = true;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = true;

		// BP_OnOverlap();
		// Activated();

	}


	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	
		if (bIsCompleted)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;


		// if (!bIsPressed)
		// 	BP_OnEndOverlap();

	}
		
	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

};