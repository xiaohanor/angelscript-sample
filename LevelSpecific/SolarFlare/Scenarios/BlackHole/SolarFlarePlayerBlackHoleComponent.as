class USolarFlarePlayerBlackHoleComponent : UActorComponent
{
	bool bIsEnabled;

	AActor FallTarget;

	UPROPERTY()
	TPerPlayer<UAnimSequence> AnimBlackHoleFalling;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	void EnableBlackHole()
	{
		bIsEnabled = true;
	}
};