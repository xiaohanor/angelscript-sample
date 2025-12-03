UCLASS(Abstract)
class USkylineAllyGrappleHatchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenLeverHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseLeverHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrapple() {}
}

class ASkylineAllyGrappleHatch : AHazeActor
{
	default ActorTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchPivot2;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	USceneComponent LeverHatchPivot;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	USceneComponent LeverPivot;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(EditInstanceOnly)
	AGrappleLaunchPoint GrappleLaunchPoint;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike LeverTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HatchTimeLike;

	bool bGrappleInitiated = false;

	UPROPERTY()
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = false;
	private UButtonMashComponent ButtonMashComp = nullptr;
	FHazeAcceleratedFloat AccOpen;

	FOnButtonMashCompleted OnCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!IsValid(GrappleLaunchPoint))
			PrintToScreen("GrappleHatch has no grapple launch point", 10.0, FLinearColor::Red);

		OnCompleted.BindUFunction(this, n"ButtomMashCompleted");

		GrappleLaunchPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleInitiated");
		GrappleLaunchPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleGrappleFinished");

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");

		LeverTimeLike.BindUpdate(this, n"LeverTimeLikeUpdate");
		LeverTimeLike.BindFinished(this, n"LeverTimeLikeFinished");
		HatchTimeLike.BindUpdate(this, n"HatchTimeLikeUpdate");
		HatchTimeLike.BindFinished(this, n"HatchTimeLikeFinished");

		GrappleLaunchPoint.AddActorDisable(this);
	}

	UFUNCTION()
	private void ButtomMashCompleted()
	{
		InteractionComp.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		Player.StopButtonMash(this);
		
		if (bGrappleInitiated)
			return;
		
		GrappleLaunchPoint.AddActorDisable(this);
		// LeverHatchTimeLike.Reverse();

		USkylineAllyGrappleHatchEventHandler::Trigger_OnCloseLeverHatch(this);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		// LeverHatchTimeLike.Play();
		UButtonMashComponent PlayerButtonMash = UButtonMashComponent::Get(Player);
		Player.StartButtonMash(MashSettings, this, OnCompleted);
		PlayerButtonMash.SetAllowButtonMashCompletion(this, false);
		// Timer::SetTimer(this, n"RemoveMashCompletionDisabler", 1.0);
		SetActorTickEnabled(true);
		ButtonMashComp = PlayerButtonMash;
		USkylineAllyGrappleHatchEventHandler::Trigger_OnOpenLeverHatch(this);
	}

	UFUNCTION()
	private void RemoveMashCompletionDisabler()
	{
		ButtonMashComp.SetAllowButtonMashCompletion(this, true);
	}

	UFUNCTION()
	private void HandleGrappleFinished(AHazePlayerCharacter Player,
	                                   UGrapplePointBaseComponent GrapplePoint)
	{
		HatchTimeLike.Play();
	}

	UFUNCTION()
	private void HandleGrappleInitiated(AHazePlayerCharacter Player,
	                                    UGrapplePointBaseComponent GrapplePoint)
	{
		LeverTimeLike.Play();
		InteractionComp.Disable(this);
		InteractionComp.KickAnyPlayerOutOfInteraction();
		bGrappleInitiated = true;
		USkylineAllyGrappleHatchEventHandler::Trigger_OnGrapple(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bShoulGrappleBeEnabled = AccOpen.Value > 0.95;
		bool bIsGrapplePointEnabled = !GrappleLaunchPoint.IsActorDisabled();
		if (bShoulGrappleBeEnabled && !bIsGrapplePointEnabled)
		{
			GrappleLaunchPoint.RemoveActorDisable(this);
		}
		else if (!bShoulGrappleBeEnabled && bIsGrapplePointEnabled)
		{
			GrappleLaunchPoint.AddActorDisable(this);
		}

		bool bIsButtonMashing = false;
		if (ButtonMashComp != nullptr)
		{
			if (!ButtonMashComp.HasControl() && ButtonMashComp.GetButtonMashProgress(this) > KINDA_SMALL_NUMBER)
				bIsButtonMashing = true;
			else if (ButtonMashComp.IsButtonMashActive(this))
				bIsButtonMashing = true;

			if (bIsButtonMashing)
			{
				if (ButtonMashComp.GetButtonMashProgress(this) < 0.95)
					AccOpen.AccelerateTo(ButtonMashComp.GetButtonMashProgress(this) * 0.2, 1.0, DeltaSeconds);
				else 
					AccOpen.AccelerateTo(1.0, 1.0, DeltaSeconds);

				LeverHatchPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -150.0, AccOpen.Value), 180.0));
			}
		}
		
		if (!bIsButtonMashing && !bGrappleInitiated && !Math::IsNearlyEqual(AccOpen.Value, 0.0))
		{
			AccOpen.SpringTo(0.0, 250.0, 0.3, DeltaSeconds);
			float BouncingOpenness = Math::Abs(AccOpen.Value);
			LeverHatchPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -100.0, BouncingOpenness), 180.0));
		}
	}

	UFUNCTION()
	private void LeverHatchTimeLikeUpdate(float CurrentValue)
	{
		LeverHatchPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -100.0, CurrentValue), 180.0));
	}

	UFUNCTION()
	private void LeverTimeLikeUpdate(float CurrentValue)
	{
		LeverPivot.SetRelativeRotation(FRotator(Math::Lerp(-5.0, -150.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void LeverTimeLikeFinished()
	{
		GrappleLaunchPoint.DetachFromActor();
		HatchTimeLike.Play();
	}

	UFUNCTION()
	private void HatchTimeLikeUpdate(float CurrentValue)
	{
		HatchPivot.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, 90.0, CurrentValue), 0.0));
		HatchPivot2.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -90.0, CurrentValue), 0.0));
	}

	UFUNCTION()
	private void HatchTimeLikeFinished()
	{
	}
};