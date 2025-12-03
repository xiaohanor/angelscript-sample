class ASummitFireSectionManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UAcidSprayContraptionResponseComponent SprayResponseComp;

	UPROPERTY(EditAnywhere)
	TArray<ASummitFireSection> FireSections;

	float FireRate = 0.2;
	float NextFireTime;

	int Index = 0;

	bool bActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SprayResponseComp.OnAcidSprayIgnite.AddUFunction(this, n"OnAcidSprayIgnite");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > NextFireTime)
		{
			NextFireTime = Time::GameTimeSeconds + FireRate;
			FireSections[Index].ActivateFire();
			Index++;

			if (Index >= FireSections.Num() - 1)
			{
				bActive = false;
				SetActorTickEnabled(false);
			}
		}
	}

	UFUNCTION()
	private void OnAcidSprayIgnite()
	{
		SetActorTickEnabled(true);

		if (!bActive)
		{
			bActive = true;
			Index = 0;
		}
	}
}