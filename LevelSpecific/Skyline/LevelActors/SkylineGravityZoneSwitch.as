class ASkylineGravityZoneSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(EditAnywhere)
	FRotator SwitchRotation;

	UPROPERTY(EditAnywhere)
	ASkylineGravityZone GravityZone;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponseComp.OnHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		GravityZone.AddActorWorldRotation(SwitchRotation);
	}
}