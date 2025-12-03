UCLASS(HideCategories = "HiddenSpline Rendering Debug Activation Collision HLOD Tags Physics DataLayers AssetUserData WorldPartition Actor LOD Cooking RayTracing TextureStreaming")
class AIslandWalkerEscapeSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSplineComponent Spline;

	UPROPERTY(EditInstanceOnly)
	AIslandWalkerRecoverSpline RecoverSpline;
}

UCLASS(HideCategories = "HiddenSpline Rendering Debug Activation Collision HLOD Tags Physics DataLayers AssetUserData WorldPartition Actor LOD Cooking RayTracing TextureStreaming")
class AIslandWalkerRecoverSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 50.0);
	default Billboard.RelativeScale3D = FVector::OneVector * 0.5; 
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSplineComponent Spline;
}
