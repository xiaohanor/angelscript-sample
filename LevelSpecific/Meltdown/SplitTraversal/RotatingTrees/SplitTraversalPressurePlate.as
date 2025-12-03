UCLASS(Abstract)
class USplitTraversalPressurePlateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundImpactedByPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundImpactedByPlayerEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlateActivated() {}
}

class ASplitTraversalPressurePlate : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyPressurePlateRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiPressurePlateRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiPressurePlateRoot)
	USceneComponent ScifiPressurePlateProgressRoot;

	FHazeTimeLike ProgressTimeLike;
	default ProgressTimeLike.UseLinearCurveZeroToOne();
	default ProgressTimeLike.Duration = 2.0;

	UPROPERTY()
	FHazeTimeLike PressureTimeLike;
	default PressureTimeLike.UseLinearCurveZeroToOne();
	default PressureTimeLike.Duration = 0.3;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	TPerPlayer<bool> bPlayerImpacting;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalStumpButton StumpButtonActor;

	UPROPERTY()
	FHazeFrameForceFeedback FrameFF;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ProgressTimeLike.BindUpdate(this, n"ProgressTimeLikeUpdate");
		ProgressTimeLike.BindFinished(this, n"ProgressTimeLikeFinished");

		PressureTimeLike.BindUpdate(this, n"PressureTimeLikeUpdate");

		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundImpactEnded");

		ScifiPressurePlateProgressRoot.SetHiddenInGame(true, true);

		StumpButtonActor = Cast<ASplitTraversalStumpButton>(AttachParentActor);
	}

	UFUNCTION()
	private void PressureTimeLikeUpdate(float CurrentValue)
	{
		FantasyPressurePlateRoot.SetRelativeLocation(FVector::UpVector * -10.0 * CurrentValue);
		ScifiPressurePlateRoot.SetRelativeLocation(FVector::UpVector * -10.0 * CurrentValue);
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if (!bPlayerImpacting[Player.OtherPlayer])
		{
			ProgressTimeLike.Play();
			USplitTraversalPressurePlateEventHandler::Trigger_OnGroundImpactedByPlayer(this);
		}

		bPlayerImpacting[Player] = true;

		ScifiPressurePlateProgressRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION()
	private void HandleGroundImpactEnded(AHazePlayerCharacter Player)
	{
		if (bActivated)
			return;

		bPlayerImpacting[Player] = false;

		if (!bPlayerImpacting[Player.OtherPlayer])
		{
			if (!ProgressTimeLike.IsPlaying())
			{
				for (auto ResponseComp : StumpButtonActor.ResponseComponents)
				{
					ResponseComp.DeactivatedButton();
				}
			}
			
			USplitTraversalPressurePlateEventHandler::Trigger_OnGroundImpactedByPlayerEnded(this);

			ProgressTimeLike.Reverse();
			PressureTimeLike.Reverse();
			BP_Deactivate();
		}
	}

	UFUNCTION()
	private void ProgressTimeLikeUpdate(float CurrentValue)
	{
		ScifiPressurePlateProgressRoot.SetRelativeScale3D(FVector(1.0, 1.0, Math::Lerp(0.0, 1.0, CurrentValue)));

		for (auto Player : Game::Players)
		{
			if (bPlayerImpacting[Player])
				ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, Player.ActorLocation);
		}
	}

	UFUNCTION()
	private void ProgressTimeLikeFinished()
	{
		if (bActivated)
			return;
		
		PrintToScreen("Finished", 3.0);

		if (!ProgressTimeLike.IsReversed())
		{
			Activate();
			PressureTimeLike.Play();

			for (auto ResponseComp : StumpButtonActor.ResponseComponents)
			{
				ResponseComp.OnActivated.AddUFunction(this, n"HandleActivated");
				ResponseComp.ActivatedButton();
			}
		}
		else
		{
			ScifiPressurePlateProgressRoot.SetHiddenInGame(true, true);
		}
	}

	UFUNCTION()
	void HandleActivated()
	{
		bActivated = true;
		USplitTraversalPressurePlateEventHandler::Trigger_OnPlateActivated(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate(){}

	UFUNCTION()
	private void Activate()
	{
		BP_Activate();
	}
};