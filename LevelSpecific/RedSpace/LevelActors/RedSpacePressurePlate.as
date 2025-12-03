event void FRedSpacePressurePlateEvent();

UCLASS(Abstract)
class ARedSpacePressurePlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlateRoot;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect EnterForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LeaveForceFeedback;

	UPROPERTY()
	FRedSpacePressurePlateEvent OnActivated;

	UPROPERTY()
	FRedSpacePressurePlateEvent OnDeactivated;

	UPROPERTY(EditInstanceOnly)
	ARedSpacePressurePlatePlatform Platform;

	UPROPERTY(EditDefaultsOnly)
	UPlayerFloorSlowdownSettings SlowdownSettings;

	TArray<AHazePlayerCharacter> PlayersOnPlate;

	bool bPlatePressed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		Player.ApplySettings(SlowdownSettings, PlayerTrigger);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(PlayerTrigger);
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (PlayersOnPlate.Contains(Player))
			return;

		PlayersOnPlate.Add(Player);
		Player.PlayForceFeedback(EnterForceFeedback, false, true, this);

		if (!bPlatePressed)
			ActivatePlate();
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (!PlayersOnPlate.Contains(Player))
			return;

		PlayersOnPlate.Remove(Player);
		Player.PlayForceFeedback(LeaveForceFeedback, false, true, this);

		if (PlayersOnPlate.Num() == 0 && bPlatePressed)
			DeactivatePlate();
	}

	void ActivatePlate()
	{
		bPlatePressed = true;

		OnActivated.Broadcast();

		BP_ActivatePlate();

		if (Platform != nullptr)
			Platform.Activate();

		URedSpacePressurePlateEffectEventHandler::Trigger_Activated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivatePlate() {}

	void DeactivatePlate()
	{
		bPlatePressed = false;

		OnDeactivated.Broadcast();

		BP_DeactivatePlate();

		if (Platform != nullptr)
			Platform.Deactivate();

		URedSpacePressurePlateEffectEventHandler::Trigger_Deactivated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivatePlate() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetOffset = bPlatePressed ? -15.0 : 0.0;
		float CurOffset = Math::FInterpTo(PlateRoot.RelativeLocation.Z, TargetOffset, DeltaTime, 8.0);
		PlateRoot.SetRelativeLocation(FVector(0.0, 0.0, CurOffset));
	}

	UFUNCTION(BlueprintPure)
	bool IsActive()
	{
		return bPlatePressed;
	}
}

class URedSpacePressurePlateEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Activated() {}
	UFUNCTION(BlueprintEvent)
	void Deactivated() {}
}