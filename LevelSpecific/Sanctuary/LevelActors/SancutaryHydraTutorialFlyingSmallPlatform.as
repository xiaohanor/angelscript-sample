UCLASS(Abstract)
class ASancutaryHydraTutorialFlyingSmallPlatform : AHazeActor
{

	UPROPERTY(DefaultComponent,RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent,  Attach = TranslateComp)
	USanctuaryFloatingSceneComponent FloatComp;

	UPROPERTY(DefaultComponent)
	USanctuaryPlayerWeightComponent WeightComp;

	UPROPERTY(DefaultComponent, Attach = FloatComp)
	UPerchPointComponent PerchPoint;

	UPROPERTY(DefaultComponent, Attach = FloatComp)
	UStaticMeshComponent PlatformMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};
