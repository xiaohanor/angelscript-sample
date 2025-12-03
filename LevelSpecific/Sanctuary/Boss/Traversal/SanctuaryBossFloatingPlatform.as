event void FSanctuaryBossFloatingPlatformSignature();

class ASanctuaryBossFloatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingSceneComponent;

	UPROPERTY(DefaultComponent, Attach = FloatingSceneComponent)
	UPlayerInheritMovementComponent PlayerInheritMovementComponent;
	default PlayerInheritMovementComponent.FollowType = EPlayerInheritMovementFollowType::FollowImpactedMesh;
	default PlayerInheritMovementComponent.Shape.Type = EHazeShapeType::Sphere;

	UPROPERTY(DefaultComponent, Attach = FloatingSceneComponent)
	USanctuaryBossHydraPlatformComponent PlatformComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossHydraResponseComponent HydraResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossAttackTriggerComponent AttackTriggerComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	FSanctuaryBossFloatingPlatformSignature OnPlatformSmashed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HydraResponseComponent.OnSmashed.AddUFunction(this, n"HandleSmashed");
	}

	UFUNCTION()
	private void HandleSmashed(ASanctuaryBossHydraHead Head)
	{
		OnPlatformSmashed.Broadcast();
	}
};