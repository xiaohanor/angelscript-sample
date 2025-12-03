class ASanctuaryTowersUnstableTraversal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFauxRotateComponent PitchRotateComp;
	default PitchRotateComp.LocalRotationAxis = FVector::RightVector;
	default PitchRotateComp.bConstrain = true;
	default PitchRotateComp.ConstrainAngleMin = -10.0;
	default PitchRotateComp.ConstrainAngleMax = 10.0;
	default PitchRotateComp.SpringStrength = 10.0;
	default PitchRotateComp.Friction = 3.0;

	UPROPERTY(DefaultComponent, Attach = PitchRotateComp)
	USanctuaryFauxRotateComponent RollRotateComp;
	default RollRotateComp.LocalRotationAxis = FVector::ForwardVector;
	default RollRotateComp.bConstrain = true;
	default RollRotateComp.ConstrainAngleMin = -10.0;
	default RollRotateComp.ConstrainAngleMax = 10.0;
	default RollRotateComp.SpringStrength = 10.0;
	default RollRotateComp.Friction = 3.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 30.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
			AttachedActor.AttachToComponent(RollRotateComp, AttachmentRule = EAttachmentRule::KeepRelative);
	}
};