UCLASS(Abstract)
class USkylineInnnerCityPortalPanelDragableEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

};	
class ASkylineInnnerCityPortalPanelDragable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsSplineFollowComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = SplineComp)
	UStaticMeshComponent DragMesh;

	UPROPERTY(DefaultComponent, Attach = SplineComp)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent, Attach = SplineComp)
	UFauxPhysicsSpringConstraint SpringComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbedd");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		SpringComp.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleGrabbedd(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent,
	                            TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		SpringComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
};