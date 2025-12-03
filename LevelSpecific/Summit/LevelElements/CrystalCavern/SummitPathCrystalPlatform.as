class ASummitPathCrystalPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
    
	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

    bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{
        if (bIsActive)
            return;

        bIsActive = true;
		BP_Activate();
	}

    UFUNCTION(BlueprintEvent)
	void BP_Activate() {
		
	}

	UFUNCTION()
	void Activate() {
		
	}

	UFUNCTION()
	void Deactivate() {
		
	}

}
