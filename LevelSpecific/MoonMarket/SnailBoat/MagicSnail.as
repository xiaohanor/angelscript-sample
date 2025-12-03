class AMagicSnail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;
	
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMoonMarketFollowSplineComp FollowComp;
	default FollowComp.bStartActive = false;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	AHazeActor TargetAttach;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		FollowComp.OnFreakyReachedEndOfSpline.AddUFunction(this, n"OnFreakyReachedEndOfSpline");
	}

	UFUNCTION()
	private void OnFreakyReachedEndOfSpline()
	{
		AttachToActor(TargetAttach, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		FollowComp.DeactivateSplineFollow();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		FollowComp.ActivateSplineFollow();
	}
};