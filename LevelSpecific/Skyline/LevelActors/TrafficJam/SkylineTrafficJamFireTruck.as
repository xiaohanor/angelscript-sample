class ASkylineTrafficJamFireTruck : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent LadderTranslateComp;
	default LadderTranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = LadderTranslateComp)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeCombatResponseComponent;

	bool bHit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeCombatResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!bHit)
		{
			bHit = true;
			LadderTranslateComp.MinX = -800.0;
			LadderTranslateComp.ApplyImpulse(LadderTranslateComp.WorldLocation, ActorForwardVector * -200.0);
			GravityBladeTargetComponent.Disable(this);
			BP_Hit();
		}
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hit()
	{
	}
};