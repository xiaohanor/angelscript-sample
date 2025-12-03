class ASkylineFireTruck : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent BladeCollison;

	UPROPERTY(DefaultComponent, Attach = BladeCollison)
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent, Attach = BladeTarget)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};