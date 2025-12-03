class ASkylineHighwayBargeContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(EditInstanceOnly)
	AHazeProp LightProp;

	UPROPERTY(EditInstanceOnly)
	UMaterialInterface GreenMaterial;

	UPROPERTY(EditInstanceOnly)
	UMaterialInterface RedMaterial;

	UPROPERTY(EditInstanceOnly)
	AActor Container;

	UPROPERTY(EditInstanceOnly)
	AHazeSpotLight SpotLight;

	private UHazePropComponent HazePropComp;
	private FVector ContainerStartLocation;
	private FVector ContainerEndLocation;
	private float ActivatedTime;
	private FHazeAcceleratedVector AccLocation;
	private bool bSwitch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazePropComp = UHazePropComponent::Get(LightProp);
		HazePropComp.SetMaterial(1, RedMaterial);
		ContainerStartLocation = Container.ActorLocation;
		ContainerEndLocation = Container.ActorLocation + -ActorForwardVector * 600;
		AccLocation.SnapTo(ContainerStartLocation);
		SpotLight.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ActivatedTime == 0 || Time::GetGameTimeSince(ActivatedTime) < 1)
			return;

		if(!bSwitch)
		{
			bSwitch = true;
			UHazePropComponent::Get(LightProp).SetMaterial(0, GreenMaterial);
			SpotLight.RemoveActorDisable(this);
		}

		AccLocation.AccelerateTo(ContainerEndLocation, 5, DeltaSeconds);
		Container.ActorLocation = AccLocation.Value;
	}

	UFUNCTION()
	void ActivateContainer()
	{
		ActivatedTime = Time::GameTimeSeconds;
	}
}