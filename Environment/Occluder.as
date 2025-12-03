
UCLASS(Abstract)
class AOccluder : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;
	default Root.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Lightblocker_Box;
    default Lightblocker_Box.CollisionProfileName = n"NoCollision";
	default Lightblocker_Box.Mobility = EComponentMobility::Static;
	
    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Lightblocker_GridBox;
    default Lightblocker_GridBox.CollisionProfileName = n"NoCollision";
	default Lightblocker_GridBox.SetHiddenInGame(true);
	default Lightblocker_GridBox.Mobility = EComponentMobility::Static;
    
	UPROPERTY(meta = (MakeEditWidget), EditAnywhere)
	FVector Size = FVector(500, 500, 500);

	UPROPERTY(EditAnywhere)
	float LocalSnapGridSize = 500;

    UPROPERTY(EditAnywhere)
	bool HiddenInGame = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Size = FVector(Math::GridSnap(Size.X, LocalSnapGridSize),
					   Math::GridSnap(Size.Y, LocalSnapGridSize),
					   Math::GridSnap(Size.Z, LocalSnapGridSize));
		
		Lightblocker_Box.SetHiddenInGame(HiddenInGame);

		Lightblocker_Box.SetRelativeScale3D(Size / 100.0);
		Lightblocker_GridBox.SetRelativeScale3D(Size / 100.0);
    }
}