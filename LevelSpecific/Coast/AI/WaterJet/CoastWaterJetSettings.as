class UCoastWaterJetSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Engage")
	FVector EngageOffset = FVector(6500.0, 100.0, 2000.0);

	UPROPERTY(Category = "Engage")
	float EngageSpeed = 8000.0;

	UPROPERTY(Category = "Engage")
	float EngageHoldingThreshold = 400.0;

	UPROPERTY(Category = "Engage")
	float EngageHoldingMaxDuration = 1.0;

	UPROPERTY(Category = "Engage")
	float EngageHoldingExtraOffset = 400.0;


	UPROPERTY(Category = "Attack")
	float AttackRange = 5000;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 0.1;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 3.0;

	UPROPERTY(Category = "Attack")
	float AttackRecoverDuration = 0.7;

	UPROPERTY(Category = "Attack")
	float AttackInterval = 0.2;

	UPROPERTY(Category = "Attack")
	float AttackPlayerDamage = 0.01;

	UPROPERTY(Category = "GrenadeAttack")
	float GrenadeAttackInterval = 0.2;

	UPROPERTY(Category = "GrenadeAttack")
	float GrenadeAttackPlayerDamage = 0.01;

	
	UPROPERTY(Category = "Damage")
	float DamageFromProjectilesFactor = 0.01;	

	UPROPERTY(Category = "Damage")
	float DamageReactionDuration = 0.2;


	UPROPERTY(Category = "Movement")
	float AirFriction = 0.6;

	UPROPERTY(Category = "Movement")
	float AtDestinationRange = 200.0;

	UPROPERTY(Category = "Movement")
	float TurnDuration = 2.0;

	UPROPERTY(Category = "Movement")
	float StopTurningDamping = 2.0;
}
