event void FIslandTurretronProjectileResponseComponent();

class UIslandTurretronProjectileResponseComponent : UActorComponent
{
	// This will trigger when the projectile detects a blocking hit with an actor holding this component.
	UPROPERTY()
	FIslandTurretronProjectileResponseComponent OnHit;
};