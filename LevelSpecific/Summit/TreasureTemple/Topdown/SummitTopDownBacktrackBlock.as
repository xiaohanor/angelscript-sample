class ASummitTopDownBacktrackBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionProfileName(n"InvisibleWall");
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditInstanceOnly)
	ABothPlayerTrigger BothPlayerTrigger;

	UPROPERTY(EditInstanceOnly)
	bool bStartActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartActive)
			ActivateBlocker();
		else
			DeactivateBlocker();
		
		if (BothPlayerTrigger != nullptr)
			BothPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"ActivateBlocker");
	}

	UFUNCTION()
	void ActivateBlocker()
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION()
	void DeactivateBlocker()
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

};