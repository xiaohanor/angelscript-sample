event void FDentistButtonActivated();

UCLASS(Abstract)
class ADentistDoubleDoorButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY()
	FHazeTimeLike ButtonTimeLike;
	default ButtonTimeLike.UseSmoothCurveZeroToOne();
	default ButtonTimeLike.Duration = 1.0;

	UPROPERTY()
	float ActiveDuration = 0.5;

	UPROPERTY()
	FDentistButtonActivated OnButtonActivated;

	UPROPERTY()
	FDentistButtonActivated OnButtonDeactivated;

	bool bActivated = false;
	bool bPermaActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"HandleGroundPound");
		ButtonTimeLike.BindUpdate(this, n"ButtonTimeLikeUpdate");
		ButtonTimeLike.BindFinished(this, n"ButtonTimeLikeFinished");
	}

	UFUNCTION()
	private void ButtonTimeLikeUpdate(float CurrentValue)
	{
		ButtonRoot.SetRelativeLocation(FVector::UpVector * -70.0 * CurrentValue);
		ButtonRoot.SetRelativeRotation(FRotator(0.0, CurrentValue * 120.0, 0.0));
	}

	UFUNCTION()
	private void ButtonTimeLikeFinished()
	{
		if (!ButtonTimeLike.IsReversed() && !bPermaActivated)
		{
			Timer::SetTimer(this, n"Deactivate", ActiveDuration);
		}
	}

	UFUNCTION()
	private void HandleGroundPound(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		if (bActivated)
			return;

		if(!GroundPoundPlayer.HasControl())
			return;

		CrumbOnGroundPounded();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnGroundPounded()
	{
		ButtonTimeLike.SetPlayRate(5.0);
		ButtonTimeLike.Play();

		bActivated = true;
		
		OnButtonActivated.Broadcast();
		BP_Audio_OnButtonActivated();
	}

	UFUNCTION()
	private void Deactivate()
	{
		ButtonTimeLike.SetPlayRate(1.0);
		ButtonTimeLike.Reverse();

		bActivated = false;

		OnButtonDeactivated.Broadcast();
		BP_Audio_OnButtonDeactivated();
	}

	/**
	 * AUDIO
	 */
	
	UFUNCTION(BlueprintEvent, Category = "Audio")
	void BP_Audio_OnButtonActivated() {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	void BP_Audio_OnButtonDeactivated() {}
};