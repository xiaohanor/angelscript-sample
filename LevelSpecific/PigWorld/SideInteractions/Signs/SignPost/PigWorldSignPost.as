asset PigWorldSignPostFartResponseSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPigWorldSignPostFartResponseCapability);
}

class APigWorldSignPost : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UStaticMeshComponent Mesh;
	default Mesh.ShadowPriority = EShadowPriority::LevelElement;

	// Eman TODO: Text? 

	UPROPERTY(DefaultComponent)
	UPigRainbowFartResponseComponent FartResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(PigWorldSignPostFartResponseSheet);

	bool bFartedOn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FartResponseComponent.OnPlayerEnter.AddUFunction(this, n"OnFartedOn");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFartedOn(AHazePlayerCharacter Player)
	{
		bFartedOn = true;

		if (FartResponseComponent.MovementResponseData.MovementType == EPigRainbowFartMovementResponseType::Rotation)
			UPigWorldSignPostEffectEventHandler::Trigger_Spin(this);
		else if (FartResponseComponent.MovementResponseData.MovementType == EPigRainbowFartMovementResponseType::Wiggle)
			UPigWorldSignPostEffectEventHandler::Trigger_Wiggle(this);
	}
}