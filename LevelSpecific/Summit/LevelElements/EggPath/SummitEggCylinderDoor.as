event void FSummitEggCylinderDoorSignature();

class ASummitEggCylinderDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent)
	USceneComponent EndPositionComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 6.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bIsPlaying;

	UPROPERTY()
	FSummitEggCylinderDoorSignature OnMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void OpenDoor()
	{
		if (MoveAnimation.IsPlaying())
			return;
		
		Game::GetMio().PlayCameraShake(CameraShake, this);
		Game::GetZoe().PlayCameraShake(CameraShake, this);
		UASummitEggCylinderDoorEffectHandler::Trigger_DoorMoving(this);
		MoveAnimation.PlayFromStart();
		
		if(ForceFeedback == nullptr)
			return;

		Game::GetMio().PlayForceFeedback(ForceFeedback, false, false, this);
		Game::GetZoe().PlayForceFeedback(ForceFeedback, false, false, this);

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		MovableObject.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		MovableObject.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		UASummitEggCylinderDoorEffectHandler::Trigger_DoorStopped(this);
	}

};

UCLASS(Abstract)
class UASummitEggCylinderDoorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorStopped() {}

}