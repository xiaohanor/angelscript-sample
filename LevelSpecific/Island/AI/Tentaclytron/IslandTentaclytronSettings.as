class UIslandTentaclytronSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Chase")
	FVector ChaseTargetOffset = FVector(600.0, 100.0, 200.0);

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 0.0;

	UPROPERTY(Category = "Chase")
	float ChaseArrivedCooldown = 0.5;


	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.1;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 3.5;
};
