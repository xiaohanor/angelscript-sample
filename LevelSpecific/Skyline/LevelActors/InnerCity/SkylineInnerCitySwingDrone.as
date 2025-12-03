UCLASS(Abstract)
class USkylineInnerCitySwingDroneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

};	
class ASkylineInnerCitySwingDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent DroneMesh;

	UPROPERTY(DefaultComponent,  Attach = TranslateComp)
	UStaticMeshComponent SwingPointMesh;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USwingPointComponent SwingPointComp;	

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"HandleSwingAttached");
		SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"HandleSwingDetached");
		ForceComp.AddDisabler(this);
	}

	
	UFUNCTION(BlueprintEvent)
	private void HandleSwingAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
	}

	UFUNCTION(BlueprintEvent)
	private void HandleSwingDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		
	}
};