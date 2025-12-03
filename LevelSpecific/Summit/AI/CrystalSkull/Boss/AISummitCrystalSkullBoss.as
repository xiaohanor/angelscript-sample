UCLASS(Abstract)
class AAISummitCrystalSkullBoss: AAISummitCrystalSkullArmoured
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSkullBossCompoundCapability");

	default ArcLauncher.bSplitTargets = true;
	default ArcLauncher.ProjectilesMultiple = 2.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitCrystalSkullBossForceFieldComponent ForceField;
	default ForceField.WorldScale3D = FVector(60.0, 60.0, 80.0);
}
