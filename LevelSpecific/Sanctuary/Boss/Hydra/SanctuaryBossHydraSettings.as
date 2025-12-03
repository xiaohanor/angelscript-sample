class USanctuaryBossHydraSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Animations")
	bool bUseAnimSequences = true;

	UPROPERTY(Category = "Animations")
	UAnimSequence IdleAnimation;

	UPROPERTY(Category = "Animations")
	UAnimSequence BiteAnimation;

	UPROPERTY(Category = "Animations")
	UAnimSequence RoarAnimation;

	UPROPERTY(Category = "Animations")
	UAnimSequence OpenJawAnimation;

	UPROPERTY(Category = "Hydra")
	bool bDisableCodeHeadOffset = false;

	UPROPERTY(Category = "Hydra")
	float MouthPitch = -21;

	UPROPERTY(Category = "Attack|Smash")
	float SmashEnterDistance = 150.0;

	UPROPERTY(Category = "Attack|Smash")
	float SmashEnterDuration = 2.4;

	UPROPERTY(Category = "Attack|Smash")
	float SmashTelegraphDuration = 2.0;

	UPROPERTY(Category = "Attack|Smash")
	float SmashTelegraphAnimationDuration = 4.0;

	UPROPERTY(Category = "Attack|Smash")
	float SmashAttackDuration = 0.7;

	UPROPERTY(Category = "Attack|Smash")
	float SmashRecoverDuration = 0.6;

	UPROPERTY(Category = "Attack|Smash")
	float SmashReturnDuration = 1.0;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathBeamLength = 7000.0;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathRadius = 130.0;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathEnterDuration = 1.8;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathTelegraphDuration = 5.0;
	
	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathTelegraphAnimationDuration = 4.0;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathSweepDuration = 1.6;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathRecoverDuration = 0.6;

	UPROPERTY(Category = "Attack|Fire Breath")
	float FireBreathReturnDuration = 1.2;

	UPROPERTY(Category = "Attack|Fire Ball")
	float FireBallEnterDuration = 0.6;

	UPROPERTY(Category = "Attack|Fire Ball")
	float FireBallAttackDuration = 0.3;

	UPROPERTY(Category = "Attack|Fire Ball")
	float FireBallReturnDuration = 0.6;

	UPROPERTY(Category = "Attack|Fire Ball")
	TSubclassOf<ASanctuaryBossHydraProjectile> FireBallProjectileClass;
}