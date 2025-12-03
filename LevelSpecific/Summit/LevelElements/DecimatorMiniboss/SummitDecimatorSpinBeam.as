event void FSummitDecimatorSpinBeamSignature();

class USummitDecimatorSpinBeamEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void MoveOnActivation() {}

	UFUNCTION(BlueprintEvent)
	void MoveOnDeactivation() {}

	UFUNCTION(BlueprintEvent)
	void StartAttack() {}

	UFUNCTION(BlueprintEvent)
	void StopAttack() {}
}

class ASummitDecimatorSpinBeam : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent BeamRootComponent;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent BallRootComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY()
	FRotator RotationSpeed = FRotator(0, 15, 0);

	UPROPERTY()
	float AnimationDuration = 1.0;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitDecimatorSpinBeamSignature OnActivated;

	UPROPERTY()
	FSummitDecimatorSpinBeamSignature OnDeactivated;

	UPROPERTY()
	FSummitDecimatorSpinBeamSignature OnAttackReset;

	UPROPERTY()
	bool bIsPlaying;

	UPROPERTY(BlueprintReadWrite)
	bool bIsActive;

	UPROPERTY(BlueprintReadOnly)
	bool bIsRunningAttack;
	bool bRotationDirection;
	bool bFlipFlopValue;

	float CurrentRotationSpeed;
	float ForwardRotationSpeed = 15;
	float BackwardsRotationSpeed = -15;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		SetActorTickEnabled(false);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsRunningAttack)
			return;

		if (bRotationDirection)
		{
			if (CurrentRotationSpeed != ForwardRotationSpeed)
			{
				CurrentRotationSpeed = Math::Lerp(CurrentRotationSpeed, ForwardRotationSpeed, 1 * DeltaSeconds);
			}
			MovableObject.AddLocalRotation(FRotator(0, (CurrentRotationSpeed * DeltaSeconds), 0 ));
			BallRootComponent.AddLocalRotation(FRotator(0, ((CurrentRotationSpeed * 2) * DeltaSeconds) * -1, 0 ));

		}
		else
		{
			if (CurrentRotationSpeed != BackwardsRotationSpeed)
			{
				CurrentRotationSpeed = Math::Lerp(CurrentRotationSpeed, BackwardsRotationSpeed, 1 * DeltaSeconds);
			}
			MovableObject.AddLocalRotation(FRotator(0, (CurrentRotationSpeed * DeltaSeconds), 0 ));
			BallRootComponent.AddLocalRotation(FRotator(0, ((CurrentRotationSpeed * 2) * DeltaSeconds) * -1, 0 ));

		}
	}

	UFUNCTION()
	void ActivateAttack()
	{
		SetActorTickEnabled(true);

		if(bFlipFlopValue){
			bFlipFlopValue = false;
		} else {
			bFlipFlopValue = true;
		}

		if (MoveAnimation.Value == 1)
			OnCompleted();
		else
			MoveAnimation.Play();

		OnActivated.Broadcast();
	}

	UFUNCTION()
	void DeactivateAttack()
	{
		bIsRunningAttack = false;

		SetActorTickEnabled(false);

		BP_DeactivateAttack();
		OnDeactivated.Broadcast();

		USummitDecimatorSpinBeamEventHandler::Trigger_StopAttack(this);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		MovableObject.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		OnCompleted();
	}

	UFUNCTION()
	void ResetAttack()
	{
		bIsActive = false;

		if (MoveAnimation.GetValue() == 1.0)
		{
			OnAttackReset.Broadcast();
		}

		
		USummitDecimatorSpinBeamEventHandler::Trigger_StopAttack(this);
	}
	
	UFUNCTION()
	void OnCompleted()
	{
		bIsPlaying = false;

		bIsRunningAttack = true;

		if (bFlipFlopValue)
		{
			bRotationDirection = false;
		}
		else
		{
			
			bRotationDirection = true;
		}

		BP_ActivateAttack();
		USummitDecimatorSpinBeamEventHandler::Trigger_StartAttack(this);
		
	}

	UFUNCTION()
	void RemoveSpinBeam()
	{
		MoveAnimation.Reverse();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateAttack()
	{

	}
	
	UFUNCTION(BlueprintEvent)
	void BP_DeactivateAttack()
	{

	}

}