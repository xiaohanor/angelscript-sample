class ACoastTrainCircuitLocke : AHazeCharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"EnemyIgnoreCharacters";
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastTrainCircuitLockeSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastTrainCircuitLockeBehaviourCompoundCapability");

    UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

    UPROPERTY(DefaultComponent)
	UBasicAIAnimationComponent AnimComp;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Movement;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

	UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UBasicBehaviourComponent BehaviourComponent;

	UPROPERTY(DefaultComponent)
	UCoastTrainCircuitLockeSplineMoveComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileLauncherComponent ProjectileLauncher;

	UFUNCTION(BlueprintCallable)
	void SetCurrentSpline(ACoastTrainCircuitLockeSpline Spline)
	{
		SplineComp.SetSpline(Spline);
	}
}