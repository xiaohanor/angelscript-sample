class AForceFieldWalls : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ForceFieldMesh;
	UPROPERTY(DefaultComponent)
	UDeathVolumeComponent Collision;

	UPROPERTY()
    FHazeTimeLike Timeline;
	default Timeline.Duration = 0.2;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float BaseOpacityIntensity = 0.75;

	UFUNCTION()
	void Disable()
	{
		Collision.DisableTrigger(this);
		Timeline.Play();
	}

	void Enable()
	{
		Collision.EnableTrigger(this);
		Timeline.Reverse();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timeline.BindUpdate(this, n"OnTimelineUpdated");
	}

	UFUNCTION()
    void OnTimelineUpdated(float CurrentValue)
	{
		ForceFieldMesh.SetScalarParameterValueOnMaterialIndex(0, n"OpacityIntensity", (1 - CurrentValue) * BaseOpacityIntensity);
	}

	
}