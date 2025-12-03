event void FMegaCompanionEvent(ASanctuaryMegaCompanion MegaCompanion, bool bIsBird);

class ASanctuaryMegaCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	default SkeletalMesh.CollisionProfileName = n"NoCollision";
	default SkeletalMesh.CollisionEnabled = ECollisionEnabled::PhysicsOnly; // Needed for physical animations
	default SkeletalMesh.AddTag(n"AutomatedRenderHidden");
    
	UPROPERTY(DefaultComponent)
	UBasicAIAnimationComponent AnimComp;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	UPROPERTY(EditDefaultsOnly)
	FTransform PlayerAttachOffset;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent DebugComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY()
	ULocomotionFeatureMegaCompanionRiding PlayerRideLocomotionFeature;

	UPROPERTY()
	bool bIsLightBird = false;

	UPROPERTY(EditAnywhere)
	FMegaCompanionEvent MegaCompanionStartDisintegrating;
	UPROPERTY(EditAnywhere)
	FMegaCompanionEvent MegaCompanionFinishedDisintegrating;

	UPROPERTY(DefaultComponent)
	UTemporalLogActorDetailsLoggerComponent LoggingComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AnimComp.Update(DeltaTime);
	}

	FLinearColor GetDebugColor()
	{
		if(bIsLightBird)
			return ColorDebug::Yellow;
		return ColorDebug::Lapis;
	}
};