UCLASS(Abstract)
class AGameShowArenaGlassWall : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StaticMeshComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGameShowArenaHeightAdjustableComponent HeightAdjustableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BlockPlayerCollision;
	default BlockPlayerCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HeightAdjustableComp.OnStartedMoving.AddUFunction(this, n"OnGlassWallStartedMoving");
		HeightAdjustableComp.OnFinishedMoving.AddUFunction(this, n"OnGlassWallFinishedMoving");
	}

	UFUNCTION()
	private void OnGlassWallFinishedMoving()
	{
		UGameShowArenaGlassWallEffectHandler::Trigger_OnFinishedMoving(this);
		BlockPlayerCollision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	}

	UFUNCTION()
	private void OnGlassWallStartedMoving()
	{
		UGameShowArenaGlassWallEffectHandler::Trigger_OnStartedMoving(this);
	}
};