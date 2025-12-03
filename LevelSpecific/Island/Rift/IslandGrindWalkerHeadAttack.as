UCLASS(Abstract)
class AIslandGrindWalkerHeadAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerA;

	UPROPERTY(EditAnywhere)
	bool bAlwaysActive = true;

	UPROPERTY(EditAnywhere)
	bool bStartActive;

	UPROPERTY(EditAnywhere)
	float Damage = 0.5;

	UPROPERTY()
	bool bCanHurtPlayer;

	FHazeTimeLike  DelayTimer;
	default DelayTimer.Duration = 1;
	default DelayTimer.UseLinearCurveZeroToOne();

	FHazeTimeLike  DangerTimer;
	default DangerTimer.Duration = 2;
	default DangerTimer.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerA.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		DelayTimer.BindUpdate(this, n"OnUpdate");
		DelayTimer.BindFinished(this, n"OnFinished");

		DangerTimer.BindUpdate(this, n"OnDangerUpdate");
		DangerTimer.BindFinished(this, n"OnDangerFinished");

		if (bStartActive)
			ActivateTheDanger();
	
	}

	UFUNCTION()
	void ActivateTheDanger()
	{
		DelayTimer.PlayFromStart();
	}


	UFUNCTION()
	void OnUpdate(float Alpha)
	{
	}

	UFUNCTION()
	void OnFinished()
	{
		BP_ActivateDanger();
		bCanHurtPlayer = true;
		DangerTimer.PlayFromStart();
	}

	UFUNCTION()
	void OnDangerUpdate(float Alpha)
	{
	}

	UFUNCTION()
	void OnDangerFinished()
	{
		if (bAlwaysActive)
			return;

		bCanHurtPlayer = false;
		BP_DeactivateDanger();
		ActivateTheDanger();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	

		if (!bCanHurtPlayer)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.DamagePlayerHealth(Damage);

	}

	
	UFUNCTION()
	void ForceStopLaserDanger()
	{
		DangerTimer.Stop();
		DelayTimer.Stop();
		bCanHurtPlayer = false;
		BP_DeactivateDanger();
		bCanHurtPlayer = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateDanger() {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateDanger() {}

};
