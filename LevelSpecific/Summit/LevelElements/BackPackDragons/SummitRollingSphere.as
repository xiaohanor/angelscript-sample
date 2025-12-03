class ASummitRollingSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent CollisionOne;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent CollisionTwo;

	UPROPERTY()
	bool bBtnOnePressed;

	UPROPERTY()
	bool bBtnTwoPressed;

	UPROPERTY()
	int CurrentPhase = 1;

	UPROPERTY()
	int FinalPhase = 4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetPhase(1);

		CollisionOne.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapBtnOne");
		CollisionTwo.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapBtnTwo");
		CollisionOne.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlapBtnOne");
		CollisionTwo.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlapBtnTwo");
	}

	UFUNCTION(CrumbFunction)
	void CrumbMoveBall()
	{
		BP_MoveBall();
	}

	UFUNCTION()
	void SetPhase(int Phase)
	{
		CrumbSetPhase(Phase);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetPhase(int Phase)
	{
		// CurrentPhase = Phase;
		BP_SetPhase(Phase);
	}

	UFUNCTION()
	void ResetBallPosition()
	{
		CrumbResetBallPosition();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetBallPosition()
	{
		if (CurrentPhase <= 1)
			return;

		CurrentPhase = 1;
		bBtnOnePressed = false;
		bBtnTwoPressed = false;
		BP_ResetBall();

	}

	UFUNCTION()
	private void OnOverlapBtnOne(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		bBtnOnePressed = true;
		BP_OnOverlapBtnOne();

		if (HasControl() && ShouldMoveBall())
			CrumbMoveBall();
	}

	UFUNCTION()
	private void OnOverlapBtnTwo(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	

		bBtnTwoPressed = true;
		BP_OnOverlapBtnTwo();

		if (HasControl() && ShouldMoveBall())
			CrumbMoveBall();
	}


	UFUNCTION()
	private void OnEndOverlapBtnOne(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	

		bBtnOnePressed = false;
		BP_OnEndOverlapBtnOne();

		// CrumbMoveBall();
	}

	UFUNCTION()
	private void OnEndOverlapBtnTwo(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	

		bBtnTwoPressed = false;
		BP_OnEndOverlapBtnTwo();

		// CrumbMoveBall();
	}

	bool ShouldMoveBall()
	{
		if (bBtnOnePressed && bBtnTwoPressed)
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_MoveBall(){	}

	UFUNCTION(BlueprintEvent)
	void BP_SetPhase(int Phase){}
	
	UFUNCTION(BlueprintEvent)
	void BP_ResetBall(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnOverlapBtnOne(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnOverlapBtnTwo(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnEndOverlapBtnOne(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnEndOverlapBtnTwo(){}


};