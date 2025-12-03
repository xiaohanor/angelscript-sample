class ASolarFlareTriggerShieldAttachContraption : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EmissiveMesh;
	default EmissiveMesh.SetHiddenInGame(true);
	default EmissiveMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void ShowEmissive(bool bShowEmissive)
	{
		EmissiveMesh.SetHiddenInGame(!bShowEmissive);
		BP_ShieldStateChanged(!bShowEmissive);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShieldStateChanged(bool bIsOn) {}
};