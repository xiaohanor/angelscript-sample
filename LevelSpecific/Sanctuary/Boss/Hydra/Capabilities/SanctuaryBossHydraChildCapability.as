UCLASS(Abstract)
class USanctuaryBossHydraChildCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ASanctuaryBossHydraHead Head;
	USanctuaryBossHydraSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Head = Cast<ASanctuaryBossHydraHead>(Owner);
		Settings = USanctuaryBossHydraSettings::GetSettings(Owner);
	}

	USanctuaryBossHydraAttackData GetAttackData() const property
	{
		return Head.AttackData;
	}
}