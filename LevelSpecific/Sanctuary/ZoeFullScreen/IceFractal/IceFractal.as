class AIceFractal : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Mesh;

    UPROPERTY(EditInstanceOnly)
    bool bExpand = true;

    AIceFractalSpawner Spawner;
    float InitializeTime;
    float TimeOffset;

    void Initialize(float InTimeOffset)
    {
        InitializeTime = Spawner.CurrentTime;
        TimeOffset = InTimeOffset;

        Expand();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(!bExpand)
            return;

        Expand();
    }

    private void Expand()
    {
        if(Spawner == nullptr)
        {
            PrintError("Spawner is unassigned on IceFractal!");
            SetActorTickEnabled(false);
            return;
        }

        if(Settings == nullptr)
        {
            PrintError("Assign a settings asset to IceFractalSpawner!");
            SetActorTickEnabled(false);
            return;
        }

        const float CurrentTime = (Spawner.CurrentTime + TimeOffset) - InitializeTime;
        if(CurrentTime > Spawner.Settings.LifeTime)
        {
            ReturnToPool();
            return;
        }

        const float CurrentAlpha = CurrentTime / Settings.LifeTime;

        const float ScaleAlpha = Spawner.Settings.ScaleCurve != nullptr ? Settings.ScaleCurve.GetFloatValue(CurrentAlpha) : CurrentAlpha;

        const float Scale = Math::Lerp(1.0, Settings.MaxScale, ScaleAlpha);
        SetActorScale3D(FVector(Scale, Scale, 1.0));

        const float HeightAlpha = Settings.HeightCurve != nullptr ? Settings.HeightCurve.GetFloatValue(CurrentAlpha) : CurrentAlpha;
        SetActorLocation(Spawner.ActorLocation + FVector(0.0, 0.0, HeightAlpha * Settings.MaxHeightOffset));
    }

    private void ReturnToPool()
    {
        Spawner.AddToIceFractalPool(this);
    }

    private UIceFractalSettings GetSettings() const property
    {
        return Spawner.Settings;
    }
}