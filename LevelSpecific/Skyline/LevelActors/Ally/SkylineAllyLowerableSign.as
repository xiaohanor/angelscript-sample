class ASkylineAllyLowerableSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComp)
	UFauxPhysicsForceComponent FauxPhysicsForceComp;
	default FauxPhysicsForceComp.Force = FVector::UpVector * 500.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		FauxPhysicsTranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge != EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
			return;

		FauxPhysicsTranslateComp.AddDisabler(this);

		Timer::ClearTimer(this, n"RemoveTranslateDisabler");
		Timer::SetTimer(this, n"RemoveTranslateDisabler", 3.0);
	}

	UFUNCTION()
	private void RemoveTranslateDisabler()
	{
		FauxPhysicsTranslateComp.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FauxPhysicsTranslateComp.ApplyImpulse(FauxPhysicsTranslateComp.WorldLocation, ActorUpVector * -1000.0);
	}
}