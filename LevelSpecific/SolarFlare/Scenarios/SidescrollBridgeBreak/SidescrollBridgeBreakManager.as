class ASidescrollBridgeBreakManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	ADeathVolume DeathVolume;

	UPROPERTY(EditAnywhere)
	TArray<APerchSpline> PerchActors;
	
	ASolarFlareVOManager VOManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();
		DisablePerches();
		DeathVolume.DisableDeathVolume(this);
	}

	UFUNCTION()
	void SetDeathEnabled()
	{
		DeathVolume.EnableDeathVolume(this);
	}

	UFUNCTION()
	void SetDeathDisabled()
	{
		DeathVolume.DisableDeathVolume(this);
	}

	UFUNCTION()
	void DisablePerches()
	{
		for (APerchSpline Perch : PerchActors)
			Perch.DisablePerchSpline(this);
	}

	UFUNCTION()
	void EnablePerches()
	{
		for (APerchSpline Perch : PerchActors)
			Perch.EnablePerchSpline(this);
	}
};