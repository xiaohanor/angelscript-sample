event void FSummitRollAttackActivatorSignature();

class ASummitRollAttackActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TailResponseMesh;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollAutoAimComponent AutoAimComp;
	default AutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = true;
	default AutoAimComp.MaxAimAngle = 70.0;
	default AutoAimComp.MaxRange = 1000.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 0.14;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitRollAttackActivatorSignature OnHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		SetActorControlSide(Game::Zoe);

		StartingTransform = ButtonComp.GetRelativeTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetRelativeTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		OnHit.Broadcast();
		MoveAnimation.Play();
		USummitRollAttackActivatorEventHandler::Trigger_OnActivated(this, Params);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		ButtonComp.SetRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		if (!MoveAnimation.IsReversed())
		{
			Timer::ClearTimer(this, n"MoveBackButton");
			Timer::SetTimer(this, n"MoveBackButton", 0.78);
		}
			

	}

	UFUNCTION()
	void MoveBackButton()
	{
		MoveAnimation.Reverse();
	}

	UFUNCTION()
	void ActivateMove()
	{
		BP_ActivateMove();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateMove()
	{

	}

};