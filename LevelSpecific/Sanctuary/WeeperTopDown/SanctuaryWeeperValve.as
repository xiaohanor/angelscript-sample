class ASanctuaryWeeperValve : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	
	UDarkPortalResponseComponent ResponseComp;


	bool bIsGrabbed; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		ResponseComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"OnReleased");
	}


	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		

	}


	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bIsGrabbed = true;
	}

	UFUNCTION()
	private void OnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bIsGrabbed = false;
	}
};