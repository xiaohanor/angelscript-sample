event void IslandWalkerHeadTargetOnBreakSignature(AIslandWalkerHeadTarget Target);
event void IslandWalkerHeadTargetOnRecoverSignature(AIslandWalkerHeadTarget Target);

class AIslandWalkerHeadTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerForceFieldComponent ForceFieldComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent RedBlueTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent RedBlueResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerForceFieldCapability");

	IslandWalkerHeadTargetOnBreakSignature OnBreak;
	IslandWalkerHeadTargetOnRecoverSignature OnRecover;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnDepleted");
	}

	UFUNCTION()
	private void OnDepleted(UIslandWalkerForceFieldComponent ForceFiedlComponent)
	{
		if(!ForceFieldComp.IsDepleted())
			return;

		AddActorDisable(this);
		OnBreak.Broadcast(this);
	}
}