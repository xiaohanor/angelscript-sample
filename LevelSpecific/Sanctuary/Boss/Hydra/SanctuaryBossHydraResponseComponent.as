event void FSanctuaryBossHydraSmashSignature(ASanctuaryBossHydraHead Head);
event void FSanctuaryBossHydraFireImpactSignature(ASanctuaryBossHydraHead Head, ASanctuaryBossHydraProjectile Projectile);

class USanctuaryBossHydraResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSanctuaryBossHydraSmashSignature OnSmashed;
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSanctuaryBossHydraFireImpactSignature OnFireImpact;

	void Smash(ASanctuaryBossHydraHead Head)
	{
		OnSmashed.Broadcast(Head);
	}

	void FireImpact(ASanctuaryBossHydraHead Head, ASanctuaryBossHydraProjectile Projectile)
	{
		OnFireImpact.Broadcast(Head, Projectile);
	}
}