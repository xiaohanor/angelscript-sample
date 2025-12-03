class ASkylineInnerCityFallingAntennaPanels : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent PitchRotateComp;
	default PitchRotateComp.LocalRotationAxis = FVector::RightVector;
	default PitchRotateComp.bConstrain = true;
	default PitchRotateComp.ConstrainAngleMin = -10.0;
	default PitchRotateComp.ConstrainAngleMax = 10.0;
	default PitchRotateComp.SpringStrength = 10.0;
	default PitchRotateComp.Friction = 3.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 30.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.0;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};