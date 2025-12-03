UCLASS(Abstract)
class AStormChaseFallingMetalObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape = FHazeShapeSettings::MakeBox(FVector(50,50,50));

	UPROPERTY(DefaultComponent)
	UAdultDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.MaxAimAngle = 60;
	default AutoAimComp.TargetShape.BoxExtents = FVector(50, 50, 50);
	default AutoAimComp.TargetShape.Type = EHazeShapeType::Box;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormChaseFallingObstacleComponent FallingComp;

	UPROPERTY(DefaultComponent, Attach = FallingComp)
	USphereComponent SphereCollision;
	default SphereCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		AddActorDisable(this);
	}
};