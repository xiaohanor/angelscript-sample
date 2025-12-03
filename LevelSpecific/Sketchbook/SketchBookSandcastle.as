class ASketchBookSandcastle : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USphereComponent OverlapComp;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }
}