UCLASS(Abstract)
class AIslandGrindFireAttackTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerA;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerB;

	UPROPERTY(EditInstanceOnly)
	AIslandGrindFireAttack AttackRef;

	AHazePlayerCharacter PlayerRef;
	bool bFirstHaveBeenTriggered;
	bool bCanBeActivated;

	bool bIsDisabled = true;

	FHazeTimeLike  DelayTimer;
	default DelayTimer.Duration = 2;
	default DelayTimer.UseLinearCurveZeroToOne();

	FHazeTimeLike  LaserTimer;
	default LaserTimer.Duration = 6;
	default LaserTimer.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerA.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapFirst");
		TriggerB.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapSecond");

		DelayTimer.BindUpdate(this, n"OnUpdate");
		DelayTimer.BindFinished(this, n"OnFinished");

		LaserTimer.BindUpdate(this, n"OnLaserUpdate");
		LaserTimer.BindFinished(this, n"OnLaserFinished");
	
	}

	UFUNCTION()
	void ActivateTheLaser()
	{
		LaserTimer.PlayFromStart();
		AttackRef.ActivateBeam();
	}


	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		// PrintToScreen("Laser can be activated");
	}

	UFUNCTION()
	void OnFinished()
	{
		PlayerRef = nullptr;
		bFirstHaveBeenTriggered = false;
		bCanBeActivated = false;
	}

	UFUNCTION()
	private void OnOverlapFirst(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	

		if (bIsDisabled)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(DelayTimer.IsPlaying())
			return;

		if (LaserTimer.IsPlaying())
			return;

		PlayerRef = Player;
		DelayTimer.PlayFromStart();
		bFirstHaveBeenTriggered = true;

	}

	UFUNCTION()
	private void OnOverlapSecond(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bIsDisabled)
			return;

		if (!bFirstHaveBeenTriggered)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player != PlayerRef)
			return;

		if (!DelayTimer.IsPlaying())
			return;

		if (LaserTimer.IsPlaying())
			return;

		if (bCanBeActivated)
			return;


		bCanBeActivated = true;
		ActivateTheLaser();

	}

	UFUNCTION()
	void OnLaserUpdate(float Alpha)
	{
		// PrintToScreen("Laser ACTIVATED");
	}

	UFUNCTION()
	void OnLaserFinished()
	{
		AttackRef.DeactivateBeam();
		PlayerRef = nullptr;
		bFirstHaveBeenTriggered = false;
		bCanBeActivated = false;
	}

	UFUNCTION()
	void ForceStopLaserTrigger()
	{
		AttackRef.DeactivateBeam();
		LaserTimer.Stop();
		DelayTimer.Stop();
		PlayerRef = nullptr;
		bFirstHaveBeenTriggered = false;
		bCanBeActivated = false;
		bIsDisabled = true;
	}

	UFUNCTION()
	void ActivateTrigger()
	{
		bIsDisabled = false;
	}

	UFUNCTION()
	void DisableTrigger()
	{
		bIsDisabled = true;
		AttackRef.DeactivateBeam();
		LaserTimer.Stop();
		DelayTimer.Stop();
		PlayerRef = nullptr;
		bFirstHaveBeenTriggered = false;
		bCanBeActivated = false;
		bIsDisabled = true;
	}

};
