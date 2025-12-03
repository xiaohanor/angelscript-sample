class UIslandOverseerDeployEyeComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<AAIIslandOverseerEye> EyeClass;

	UPROPERTY()
	bool bBlue;

	UPROPERTY(EditInstanceOnly)
	AIslandOverseerEyeAttackSpline IdleSplineActor;

	UPROPERTY(EditInstanceOnly)
	AIslandOverseerEyeAttackSpline FlyBySplineActor;

	UPROPERTY(EditInstanceOnly)
	AIslandOverseerEyeAttackSpline FlyByUpperSplineActor;

	AAIIslandOverseerEye Eye;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Eye = SpawnActor(EyeClass, bDeferredSpawn = true, Level = Owner.Level);
		Eye.MakeNetworked(Owner, this);
		Eye.Boss = Cast<AHazeCharacter>(Owner);
		Eye.EyesComp = this;
		Eye.bBlue = bBlue;
		FinishSpawningActor(Eye);
		Eye.ActorLocation = WorldLocation;
		Eye.ActorRotation = WorldRotation;
		Eye.MovementComponent.ApplyFollowEnabledOverride(Eye, EMovementFollowEnabledStatus::FollowEnabled);
		Eye.MovementComponent.FollowComponentMovement(this, Eye, FollowType = EMovementFollowComponentType::Teleport, Priority = EInstigatePriority::Normal);
	}
}