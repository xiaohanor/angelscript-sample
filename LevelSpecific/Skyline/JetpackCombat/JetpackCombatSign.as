class AJetpackCombatSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent RotateComp1;

	UPROPERTY(DefaultComponent, Attach = RotateComp1)
	UFauxPhysicsAxisRotateComponent RotateComp2;

	UPROPERTY(DefaultComponent, Attach = RotateComp2)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegistrationComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void Collapse()
	{
		PlayerWeightComp.AddDisabler(this);
		RotateComp1.SpringStrength = 0.0;
		RotateComp2.SpringStrength = 0.0;
		TranslateComp.SpringStrength = 0.0;
		BP_Collapse();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Collapse()
	{}
};