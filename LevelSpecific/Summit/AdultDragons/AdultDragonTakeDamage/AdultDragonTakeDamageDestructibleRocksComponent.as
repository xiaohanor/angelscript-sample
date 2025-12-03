event void FOnDestructibleRockHit(USceneComponent HitComponent, AHazePlayerCharacter Player);

class UAdultDragonTakeDamageDestructibleRocksComponent : UActorComponent
{
	UPROPERTY()
	FOnDestructibleRockHit OnDestructibleRockHit;

	UPROPERTY()
	float Damage = 0.2;

	UFUNCTION(CrumbFunction)
	void CrumbActivateStruckRock(USceneComponent HitComponent, AHazePlayerCharacter Player, TSubclassOf<UDamageEffect> DamageEffect, TSubclassOf<UDeathEffect> DeathEffect)
	{
		ActivateStruckRock(HitComponent, Player, DamageEffect, DeathEffect);
	}

	void ActivateStruckRock(USceneComponent HitComponent, AHazePlayerCharacter Player, TSubclassOf<UDamageEffect> DamageEffect, TSubclassOf<UDeathEffect> DeathEffect)
	{
		FVector Direction = (Player.ActorCenterLocation - HitComponent.Owner.ActorLocation).GetSafeNormal();
		Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(Direction), DamageEffect, DeathEffect);
		OnDestructibleRockHit.Broadcast(HitComponent, Player);
	}
}