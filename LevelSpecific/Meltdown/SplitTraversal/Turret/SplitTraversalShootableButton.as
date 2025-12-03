event void FOnSplitTraversalShootableButtonFullyPressed();

class ASplitTraversalShootableButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent)
	USplitTraversalTurretProjectileResponseComponent ResponseComp;

	UPROPERTY()
	FOnSplitTraversalShootableButtonFullyPressed OnFullyPressed;

	bool bActivated = false;

	UPROPERTY()
	FHazeTimeLike ButtonPressedTimeLike;
	default ButtonPressedTimeLike.UseSmoothCurveZeroToOne();
	default ButtonPressedTimeLike.Duration = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ButtonPressedTimeLike.BindUpdate(this, n"ButtonPressedTimeLikeUpdate");
		ButtonPressedTimeLike.BindFinished(this, n"ButtonPressedTimeLikeFinished");
		ResponseComp.OnHit.AddUFunction(this, n"HandleHit");
	}

	UFUNCTION()
	private void HandleHit()
	{
		if (bActivated)
			return;

		bActivated = true;
		ButtonPressedTimeLike.Play();
	}

	UFUNCTION()
	private void ButtonPressedTimeLikeUpdate(float CurrentValue)
	{
		ButtonRoot.SetRelativeLocation(FVector::ForwardVector * Math::Lerp(0.0, -50.0, CurrentValue));
	}

	UFUNCTION()
	private void ButtonPressedTimeLikeFinished()
	{
		BP_FullyPressed();
		OnFullyPressed.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_FullyPressed() 
	{
	}
};