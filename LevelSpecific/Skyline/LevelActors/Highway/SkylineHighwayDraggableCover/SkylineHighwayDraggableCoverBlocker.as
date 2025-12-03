class ASkylineHighwayDraggableCoverBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BladeCollision;
	default BladeCollision.bGenerateOverlapEvents = false;
	default BladeCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BladeCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent TargetComp;
	default TargetComp.AimRayType = EGravityBladeCombatAimRayType::Camera;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent GravityBladeCombatInteractionResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeCombatInteractionResponseComp.OnHit.AddUFunction(this, n"HandleHit");
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		DestroyActor();
	}
}