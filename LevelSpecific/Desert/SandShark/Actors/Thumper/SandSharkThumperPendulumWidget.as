class USandSharkThumperPendulumWidget : UHazeUserWidget
{
	UPROPERTY()
	float PendulumPosition = 0;

	UPROPERTY()
	float SuccessFraction = 0.3;

	UPROPERTY()
	float BufferSuccessFraction = 0.3;

	UPROPERTY()
	float MaxAngle = 130;

	UPROPERTY()
	float CurrentPendulumAngle = 0;

	UPROPERTY()
	bool bHasInteractingPlayer = false;

	UPROPERTY()
	bool bIsTemporarilyDisabled = false;

	UPROPERTY()
	bool bShowBufferRange = false;

	UPROPERTY()
	ESandSharkPendulumActiveDangerZoneState ActiveDangerZoneState;

	UFUNCTION(BlueprintEvent)
	void BP_PendulumFail()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_PendulumSuccess()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_PendulumCompleted()
	{}
}