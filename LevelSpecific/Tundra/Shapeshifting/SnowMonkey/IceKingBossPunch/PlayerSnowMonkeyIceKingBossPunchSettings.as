struct FTundraPlayerSnowMonkeyIceKingBossPunchTypeSettings
{
	UPROPERTY()
	int BossPunchesAmount = 6;

	UPROPERTY()
	bool bDoBackFlip = true;

	UPROPERTY()
	bool bAutomaticallyPunchFirstPunch = false;

	UPROPERTY()
	bool bAutomaticallyPunchSecondPunch = false;

	UPROPERTY(Meta = (EditCondition = "bAutomaticallyPunchFirstPunch", EditConditionHides))
	float DelayBeforeFirstPunch = 0.0;

	UPROPERTY()
	bool bAutomaticallyPunchLastPunch = true;

	UPROPERTY()
	float MinimumPunchCooldown = 0.25;

	UPROPERTY(Meta = (EditCondition = "!bDoBackFlip", EditConditionHides))
	float LastAnimationDuration = 1.27;

	UPROPERTY(Meta = (EditCondition = "bDoBackFlip", EditConditionHides))
	float TimeToBackFlipAfterLastPunch = 0.0;

	UPROPERTY()
	float BossPunchEnterDuration = 0.5;
}

class UTundraPlayerSnowMonkeyIceKingBossPunchSettings : UHazeComposableSettings
{
	/* The interpolation of how the boss will enter the point */
	UPROPERTY()
	FRuntimeFloatCurve BossPunchEnterCurve;
	default BossPunchEnterCurve.AddDefaultKey(0.0, 0.0);
	default BossPunchEnterCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	float BossPunchEnterRotationSpeed = 7.0;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchTypeSettings FirstTypeSettings;
	default FirstTypeSettings.bAutomaticallyPunchFirstPunch = true;
	default FirstTypeSettings.DelayBeforeFirstPunch = 0.2;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchTypeSettings SecondTypeSettings;
	default SecondTypeSettings.bAutomaticallyPunchFirstPunch = true;
	default SecondTypeSettings.DelayBeforeFirstPunch = 0.2;

	UPROPERTY()
	FTundraPlayerSnowMonkeyIceKingBossPunchTypeSettings FinalTypeSettings;
	default FinalTypeSettings.bDoBackFlip = false;
	default FinalTypeSettings.bAutomaticallyPunchFirstPunch = true;
	default FinalTypeSettings.DelayBeforeFirstPunch = 0.2;
	default FinalTypeSettings.bAutomaticallyPunchSecondPunch = true;
	default FinalTypeSettings.bAutomaticallyPunchLastPunch = false;
	default FinalTypeSettings.MinimumPunchCooldown = 0.5;
	default FinalTypeSettings.BossPunchesAmount = 9;
	default FinalTypeSettings.BossPunchEnterDuration = SMALL_NUMBER;
}