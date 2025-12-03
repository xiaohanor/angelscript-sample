event void FGarbageRoomPressurePlateEvent();

UCLASS(Abstract)
class AGarbageRoomPressurePlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlateRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ActivateTimeLike;

	UPROPERTY()
	FGarbageRoomPressurePlateEvent OnActivated;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateTimeLike.BindUpdate(this, n"UpdateActivate");
		ActivateTimeLike.BindFinished(this, n"FinishActivate");

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	UFUNCTION(BlueprintCallable)
	void ActivateBacktrack()
	{
		if (bActivated)
			return;

		bActivated = true;
		ActivateTimeLike.PlayFromStart();

		OnActivated.Broadcast();

		//UGarbageRoomPressurePlateEffectEventHandler::Trigger_Activated(this);

		BP_Activate();
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (bActivated)
			return;

		bActivated = true;
		ActivateTimeLike.PlayFromStart();

		OnActivated.Broadcast();

		UGarbageRoomPressurePlateEffectEventHandler::Trigger_Activated(this);

		BP_Activate();
	}

	UFUNCTION()
	private void UpdateActivate(float CurValue)
	{
		float Offset = Math::Lerp(0.0, -10.0, CurValue);
		PlateRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));
	}

	UFUNCTION()
	private void FinishActivate()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}
}