class ADarkCaveSpiritMetalCover : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCapsuleComponent BlockingCollision;
	default BlockingCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BlockingCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default BlockingCollision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	bool bPointLightOff;
	float CurrentIntensity = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnNightQueenMetalMelted.AddUFunction(this, n"Melted");
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bPointLightOff)
			return;
		
		CurrentIntensity = Math::FInterpConstantTo(CurrentIntensity, 0.0, DeltaSeconds, CurrentIntensity * 4);
		BP_SetLightIntensity(CurrentIntensity);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetLightIntensity(float Intensity) {}

	UFUNCTION()
	private void Melted()
	{
		bPointLightOff = true;
		BlockingCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		AddActorDisable(this);
	}
};