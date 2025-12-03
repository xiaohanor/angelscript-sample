event void FPerformAction();

class ASoftSplitRader : AWorldLinkDoubleActor
{

	UPROPERTY(DefaultComponent, Attach = SciFiRoot)
	UHazeSkeletalMeshComponentBase SciFiRader;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UHazeSkeletalMeshComponentBase FantasyRader;

	UPROPERTY()
	FPerformAction ActionPerformed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
				
	}

	UFUNCTION(BlueprintCallable)
	void Bp_PerformAction()
	{
		ActionPerformed.Broadcast();				
	}

};