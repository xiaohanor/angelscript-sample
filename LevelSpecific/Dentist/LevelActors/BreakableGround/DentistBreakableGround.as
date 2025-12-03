event void FDentistBreakableGroundSignature();

UCLASS(Abstract)
class ADentistBreakableGround : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = ShakeRoot)
	USceneComponent GlowRoot;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY()
	FHazeTimeLike ShakeTimeLike;
	default ShakeTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike GlowTimeLike;
	default GlowTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	float GroundPoundDuration = 0.5;

	UPROPERTY(EditInstanceOnly)
	bool bHeadBonk = false;

	UPROPERTY()
	FDentistBreakableGroundSignature OnBreak;

	TPerPlayer<float> LastGroundPound;
	bool bIsBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bHeadBonk)
			ImpactCallbackComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"HandleCeilingImpact");
		
		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"HandleGroundPound");
		ShakeTimeLike.BindUpdate(this, n"ShakeTimeLikeUpdate");
		GlowTimeLike.BindUpdate(this, n"GlowTimeLikeUpdate");
		GlowRoot.SetRelativeScale3D(FVector(SMALL_NUMBER));
	}

	UFUNCTION()
	private void GlowTimeLikeUpdate(float CurrentValue)
	{
		GlowRoot.SetRelativeScale3D(FVector(Math::Lerp(SMALL_NUMBER, 1.0, CurrentValue)));
	}

	UFUNCTION()
	private void HandleCeilingImpact(AHazePlayerCharacter Player)
	{
		GroundImpacted(Player, true);
		
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);
	}

	UFUNCTION()
	private void HandleGroundPound(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		GroundImpacted(GroundPoundPlayer, false);
	}	

	private void GroundImpacted(AHazePlayerCharacter Player, bool bIsHeadBonk)
	{
		if(!Player.HasControl())
			return;

		CrumbGroundImpacted(Player, bIsHeadBonk);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbGroundImpacted(AHazePlayerCharacter Player, bool bIsHeadBonk)
	{
		if(bIsBroken)
			return;

		GlowTimeLike.PlayFromStart();

		LastGroundPound[Player] = Time::GameTimeSeconds;

		FDentistBreakableGroundOnImpactEventData EventData;
		EventData.bIsHeadBonk = bIsHeadBonk;
		UDentistBreakableGroundEventHandler::Trigger_OnImpact(this, EventData);

		ShakeTimeLike.PlayFromStart();

		if (HasRecentlyGroundPounded(Game::Mio) && HasRecentlyGroundPounded(Game::Zoe))
			CrumbBreak();
	}

	UFUNCTION()
	private void ShakeTimeLikeUpdate(float CurrentValue)
	{
		ShakeRoot.SetRelativeLocation(FVector::RightVector * CurrentValue * 3.0);
	}

	private bool HasRecentlyGroundPounded(AHazePlayerCharacter Player)
	{
		if (Time::GetGameTimeSince(LastGroundPound[Player]) < GroundPoundDuration)
			return true;
		else
			return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBreak()
	{
		if(bIsBroken)
			return;

		bIsBroken = true;
		UDentistBreakableGroundEventHandler::Trigger_OnBreak(this);
		OnBreak.Broadcast();
		CameraShakeForceFeedbackComponent.ForceFeedbackScale = 1.0;
		CameraShakeForceFeedbackComponent.CameraShakeScale = 1.0;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		AddActorDisable(this);
	}
};