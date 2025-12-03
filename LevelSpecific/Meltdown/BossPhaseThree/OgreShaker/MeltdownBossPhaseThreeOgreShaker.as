event void FOnShakesComplete();

class AMeltdownBossPhaseThreeOgreShaker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;
	default PortalMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;
	default ListComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditAnywhere)
	AMeltdownPhaseThreeBoss RaderRef;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeOgreAttackIntro> OgreSpawnIntro;

	UPROPERTY()
	FOnShakesComplete ShakeComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		RaderRef.StartAttack(EMeltdownPhaseThreeAttack::OgreShaker);
	}
	

	UPROPERTY()
	UTexture2D PortalTextureOgre;

	UFUNCTION(BlueprintCallable)
	void OpenPortal()
	{
		PortalMesh.SetHiddenInGame(false);
		RaderRef.SetPortalState(PortalMesh, PortalTextureOgre);
	}

	UFUNCTION(BlueprintCallable)
	void HidePortal()
	{
		PortalMesh.SetHiddenInGame(true);
		AddActorDisable(this);
	}
};