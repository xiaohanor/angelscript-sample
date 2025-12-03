class UVODamageDeathSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bDamageEnabled = true;

	UPROPERTY()
	bool bDeathEnabled = true;
}

asset DamageDeathVoDisabled of UVODamageDeathSettings
{
	bDamageEnabled = false;
	bDeathEnabled = false;
}