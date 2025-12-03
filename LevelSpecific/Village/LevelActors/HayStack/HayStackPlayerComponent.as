class UHayStackPlayerComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence MioDiveAnim;

	UPROPERTY()
	UAnimSequence ZoeDiveAnim;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> DiveCamShake;

	UPROPERTY()
	UForceFeedbackEffect LandFF;

	AHayStack CurrentHayStack = nullptr;

	bool bDiving = false;
	FVector StartLocation;
	float StartYaw;

	UFUNCTION()
	void StartDive(FVector Loc, float Yaw)
	{
		StartLocation = Loc;
		StartYaw = Yaw;
		
		bDiving = true;
	}
}