event void FSplitTraversalStumpButtonActivated();
event void FSplitTraversalStumpButtonDeactivated();
event void FSplitTraversalStumpButtonPulseArrived();

class USplitTraversalButtonResponseComponent : UActorComponent
{
	//TODO MAKE A NETWORK HANDSHAKE!! sel

	UPROPERTY(EditInstanceOnly)
	TArray<ASplitTraversalStumpButton> Buttons;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplitTraversalPressurePlate> PressurePlates;

	UPROPERTY()
	FSplitTraversalStumpButtonDeactivated OnActivated;
	UPROPERTY()
	FSplitTraversalStumpButtonDeactivated OnDeactivated;
	UPROPERTY()
	FSplitTraversalStumpButtonPulseArrived OnPulseArrived;

	int ActiveButtons;
	bool bPulseArrived;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Button : Buttons)
		{
			Button.ResponseComponents.Add(this);
			OnActivated.AddUFunction(Button, n"HandleActivated");
		}
	}

	void ActivatedButton()
	{
		ActiveButtons++;

		PrintToScreen("Activated" + ActiveButtons, 3.0);

		if (!(ActiveButtons < Buttons.Num()) && HasControl())
			CrumbActivate();
	}

	void DeactivatedButton()
	{
		ActiveButtons--;

		PrintToScreen("Deactivated" + ActiveButtons, 3.0);

		if (HasControl())
			CrumbDeactivate();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate()
	{
		OnActivated.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivate()
	{
		OnDeactivated.Broadcast();
	}
}

UCLASS(Abstract)
class USplitTraversalStumpButtonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JumpOff() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activated() {}
}

class ASplitTraversalStumpButton : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UPerchPointComponent PerchCompScifi;

	UPROPERTY(DefaultComponent, Attach = PerchCompScifi)
	UPerchEnterByZoneComponent EnterZoneScifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UPerchPointComponent PerchCompFantasy;

	UPROPERTY(DefaultComponent, Attach = PerchCompFantasy)
	UPerchEnterByZoneComponent EnterZoneFantasy;

	UPROPERTY(EditInstanceOnly)
	AActor FantasyCableActor;
	UHazeSplineComponent FantasySplineComp;

	UPROPERTY(EditInstanceOnly)
	AActor ScifiCableActor;
	UHazeSplineComponent ScifiSplineComp;

	UPROPERTY()
	TSubclassOf<ASplitTraversalCableFlower> CableFlowerClass;

	UPROPERTY()
	UNiagaraSystem SparkVFX;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UNiagaraComponent ElectricityVFXComp;

	UPROPERTY()
	float SpawnFlowerInterval = 0.2;

	UPROPERTY(EditAnywhere)
	float DelayedActivationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bSpawnFlower = false;

	UPROPERTY()
	UForceFeedbackEffect FFEffect;

	UPROPERTY()
	FHazeTimeLike CableProgressTimeLike;
	default CableProgressTimeLike.UseLinearCurveZeroToOne();
	default CableProgressTimeLike.Duration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bReverseOrder;

	TArray<USplitTraversalButtonResponseComponent> ResponseComponents;

	int PerchingPlayers;
	bool bActive = false;
	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		PerchCompFantasy.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandlePerchStart");
		PerchCompScifi.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandlePerchStart");
		PerchCompFantasy.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandlePerchStopped");
		PerchCompScifi.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandlePerchStopped");

		FantasySplineComp = Spline::GetGameplaySpline(FantasyCableActor, this);
		ScifiSplineComp = Spline::GetGameplaySpline(ScifiCableActor, this);

		if (FantasySplineComp != nullptr && ScifiSplineComp != nullptr)
		{	
			CableProgressTimeLike.BindUpdate(this, n"CableProgressTimeLikeUpdate");	
			CableProgressTimeLike.BindFinished(this, n"CableProgressTimeLikeFinished");
		}
	}

	UFUNCTION()
	void DisableButtonBacktracking()
	{
		PerchCompFantasy.OnPlayerStartedPerchingEvent.Unbind(this, n"HandlePerchStart");
		PerchCompScifi.OnPlayerStartedPerchingEvent.Unbind(this, n"HandlePerchStart");
		PerchCompFantasy.OnPlayerStoppedPerchingEvent.Unbind(this, n"HandlePerchStopped");
		PerchCompScifi.OnPlayerStoppedPerchingEvent.Unbind(this, n"HandlePerchStopped");
	}

	UFUNCTION()
	private void HandlePerchStopped(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		//Just making sure our Count cant go negative as a failsafe
		if(PerchingPlayers > 0)
			PerchingPlayers--;
		
		UpdatePerchStatus();

		USplitTraversalStumpButtonEventHandler::Trigger_JumpOff(this);
	}

	UFUNCTION()
	private void HandlePerchStart(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchingPlayers++;
		UpdatePerchStatus();

		Player.PlayForceFeedback(FFEffect, false, true, this);

		USplitTraversalStumpButtonEventHandler::Trigger_Landed(this);
	}

	UFUNCTION(BlueprintCallable)
	void SetButtonToFinishActivated()
	{
		bActivated = true;
	}

	UFUNCTION()
	private void UpdatePerchStatus()
	{
		if (!bActive && PerchingPlayers > 0)
		{
			BP_Activated();
			bActive = true;

			for (auto ResponseComp : ResponseComponents)
			{
				ResponseComp.ActivatedButton();
			}
		}

		if (bActive && PerchingPlayers == 0)
		{
			BP_Dectivated();
			bActive = false;

			for (auto ResponseComp : ResponseComponents)
			{
				ResponseComp.DeactivatedButton();
			}
		}
	}

	UFUNCTION()
	void HandleActivated()
	{
		if (bActivated)
			return;

		bActivated = true;
		
		FTransform Transform = GetTransformAtSplineFraction(ScifiSplineComp, 0.0, !bReverseOrder);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, Transform.Location);

		USplitTraversalStumpButtonEventHandler::Trigger_Activated(this);

		Timer::SetTimer(this, n"DelayedActivation", DelayedActivationDuration);
	}

	UFUNCTION()
	private void DelayedActivation()
	{
		CableProgressTimeLike.Play();
		ElectricityVFXComp.Activate();

		if (bSpawnFlower)
			SpawnFlower();
	}
	
	UFUNCTION()
	private void CableProgressTimeLikeUpdate(float CurrentValue)
	{
		FTransform Transform = GetTransformAtSplineFraction(ScifiSplineComp, CurrentValue, bReverseOrder);

		ElectricityVFXComp.SetWorldLocationAndRotation(Transform.Location, Transform.Rotation);

		FHazeFrameForceFeedback FrameFF;
		FrameFF.LeftMotor = 0.4;
		FrameFF.RightMotor = 0.4;

		ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, Transform.Location, 300.0, 3000.0);
		ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, Transform.Location - FVector::ForwardVector * 500000.0, 300.0, 3000.0);
	}

	UFUNCTION()
	private void CableProgressTimeLikeFinished()
	{
		Timer::ClearTimer(this, n"SpawnFlower");
		ElectricityVFXComp.SetHiddenInGame(true);

		FTransform Transform = GetTransformAtSplineFraction(ScifiSplineComp, 1.0, !bReverseOrder);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, Transform.Location);

		for (auto Player : Game::Players)
		{
			Player.PlayForceFeedback(FFEffect, false, true, this);
		}

		for (auto ResponseComp : ResponseComponents)
		{
			if (ResponseComp.bPulseArrived)
				return;

			ResponseComp.bPulseArrived = true;
			ResponseComp.OnPulseArrived.Broadcast();
		}
	}

	private FTransform GetTransformAtSplineFraction(UHazeSplineComponent SplineComp, float SplineFraction, bool bReversedOrder)
	{
		FTransform Transform;
		float Fraction;

		if (bReversedOrder)
			Fraction = SplineFraction;
		else
			Fraction = 1.0 - SplineFraction;

		Transform.Location = SplineComp.GetWorldLocationAtSplineFraction(Fraction);
		Transform.Rotation = SplineComp.GetWorldRotationAtSplineFraction(Fraction);

		return Transform;
	}


	UFUNCTION()
	private void SpawnFlower()
	{
		FTransform Transform = GetTransformAtSplineFraction(FantasySplineComp, CableProgressTimeLike.GetValue(), bReverseOrder);
		FRotator Rotation = Transform.Rotation.Rotator();
		Rotation.Roll = Math::RandRange(0.0, 360.0);

		SpawnActor(CableFlowerClass, Transform.Location, Rotation);

		Timer::SetTimer(this, n"SpawnFlower", SpawnFlowerInterval);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_Dectivated()
	{}
};