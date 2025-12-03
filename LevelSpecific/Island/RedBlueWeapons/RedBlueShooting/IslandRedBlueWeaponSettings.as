class UIslandRedBlueWeaponSettings : UHazeComposableSettings
{
	// Is the weapons equipped by default
	UPROPERTY(Category = "Weapon")
	bool bStartWithEquippedWeapons = true;

	UPROPERTY(Category = "Weapon")
	ECollisionChannel TraceChannel = ECollisionChannel::WeaponTracePlayer;

	UPROPERTY(Category = "Weapon")
	float WeaponMaxTraceLength = 10000;

	UPROPERTY(Category = "Weapon")
	float BlendArmsDownToThighsDuration = 0.3;

	// How long after the input is held, we can start shooting
	UPROPERTY(Category = "Bullet")
	float StartShootDelay = 0.05;
}
