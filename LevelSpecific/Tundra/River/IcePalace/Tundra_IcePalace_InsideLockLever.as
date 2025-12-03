event void FIcePalaceLeverEvent();
class ATundra_IcePalace_InsideLockLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingOneShotInteractionComponent OneShotInteractionComp;

	UPROPERTY(DefaultComponent, Attach = OneShotInteractionComp)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bAbsoluteScale = true;
	default PreviewMesh.RelativeScale3D = FVector::OneVector;

	float LeverTimerDuration = 25;
	float LeverTimer = 0;
	float LeverRotationTickTimer = 0;
	float TotalDegreesToAdd = 130;
	float LeverRotationTickAmount = TotalDegreesToAdd / LeverTimerDuration;
	bool bShouldTickLeverTimer = false;
	FRotator LeverTargetRotation = FRotator(65, 0, 0);

	UPROPERTY()
	FIcePalaceLeverEvent OnLeverActivated;
	UPROPERTY()
	FIcePalaceLeverEvent OnLeverReset;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_IcePalace_InsideLockCog> ConnectedCogs;

	UPROPERTY()
	FHazeTimeLike MoveLeverTimelike;
	default MoveLeverTimelike.Duration = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		OneShotInteractionComp.OnInteractionStarted.AddUFunction(this, n"OneShotInteractionStarted");
		MoveLeverTimelike.BindUpdate(this, n"OnMoveLeverTimelikeUpdate");
		MoveLeverTimelike.BindFinished(this, n"OnMoveLeverTimelikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(UTundraPlayerFairyComponent::Get(Game::Zoe).GetShapeMesh().IsPlayingAnimAsSlotAnimation(OneShotInteractionComp.OneShotShapeSettings[Game::Zoe].SmallShape.Animation))
		{
			if(Game::Zoe.Mesh.CanRequestLocomotion())
				Game::Zoe.RequestLocomotion(n"Movement", this);
		}

		MeshRoot.SetRelativeRotation(Math::RInterpTo(MeshRoot.RelativeRotation, LeverTargetRotation, DeltaSeconds, 8));

		if(!bShouldTickLeverTimer)
			return;

		LeverRotationTickTimer += DeltaSeconds;
		LeverTimer += DeltaSeconds;

		if(LeverRotationTickTimer >= 1)
		{
			LeverRotationTickTimer = 0;
			LeverTargetRotation = LeverTargetRotation.Compose(FRotator(LeverRotationTickAmount, 0, 0));

			for(auto Cog : ConnectedCogs)
			{
				Cog.GetNewTargetRotation(LeverRotationTickAmount);
			}

			FKeyHoleLeverParams Params;
			Params.Lever = this;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnLeverTicking(this, Params);
		}

		if(LeverTimer > LeverTimerDuration)
		{
			bShouldTickLeverTimer = false;
			LeverTimer = 0;
			LeverTargetRotation = FRotator(65, 0, 0);
			OnLeverReset.Broadcast();

			for(auto Cog : ConnectedCogs)
			{
				Cog.LeverStopped();
			}

			FKeyHoleLeverParams Params;
			Params.Lever = this;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnLeverStopped(this, Params);
			
			if(HasControl())
				Timer::SetTimer(this, n"ReactivateLeverInteraction", 1);
		}
	}

	UFUNCTION()
	void ReactivateLeverInteraction()
	{
		CrumbReactivateLeverInteraction();
	}

	UFUNCTION(CrumbFunction)
	void CrumbReactivateLeverInteraction()
	{
		OneShotInteractionComp.Enable(this);
	}

	UFUNCTION()
	private void OnMoveLeverTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FQuat::Slerp(FRotator(65, 0, 0).Quaternion(), FRotator(-65, 0, 0).Quaternion(), CurrentValue));
	}

	UFUNCTION()
	private void OneShotInteractionStarted(UInteractionComponent InteractionComponent,
	                                       AHazePlayerCharacter Player)
	{
		Timer::SetTimer(this, n"MoveLeverDelayed", 0.7);
		BP_PullLeverFF();
	}

	UFUNCTION()
	private void MoveLeverDelayed()
	{
		MoveLeverTimelike.PlayFromStart();
		OneShotInteractionComp.Disable(this);

		for(auto Cog : ConnectedCogs)
		{
			Cog.StartInitialRotation(130);
		}

		FKeyHoleLeverParams Params;
		Params.Lever = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnLeverPulled(this, Params);
	}

	UFUNCTION()
	private void OnMoveLeverTimelikeFinished()
	{
		OnLeverActivated.Broadcast();
		LeverTargetRotation = MeshRoot.RelativeRotation;
		Timer::SetTimer(this, n"StartTicking", 2);
	}

	UFUNCTION()
	void StartTicking()
	{
		LeverRotationTickTimer = 1;
		bShouldTickLeverTimer = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopLever()
	{
		bShouldTickLeverTimer = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_PullLeverFF(){}
};