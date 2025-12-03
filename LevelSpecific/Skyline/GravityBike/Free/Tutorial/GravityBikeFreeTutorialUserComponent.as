class UGravityBikeFreeTutorialUserComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptThrottle;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptJump;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptDrift;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptChargeWeapon;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptFireWeapon;

	UPROPERTY(EditAnywhere)
	FVector AttachOffset = FVector(0.0, 0.0, 45.0);

	UPROPERTY(EditAnywhere)
	float ScreenSpaceOffset = 100.0;	
};