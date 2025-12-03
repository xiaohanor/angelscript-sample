UCLASS(Abstract)
class USkylineCutieSideInteractEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLegTickle(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLegRemoved() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLegThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEarTickle(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEarRemoved() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEarThrown() {}

}
class ASkylineCutieSideInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASkylineCutieSlingable CutieLeg;

	UPROPERTY(EditAnywhere)
	ASkylineCutieSlingable CutieEar;

	bool bLegGrabbed = false;
	bool bEarGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CutieLeg.GravityWhipResponseComponent.OnStartGrabSequence.AddUFunction(this, n"HandleStartGrabLeg");
		CutieEar.GravityWhipResponseComponent.OnStartGrabSequence.AddUFunction(this, n"HandleStartGrabEar");
		CutieLeg.OnWhipSlingableGrabbed.AddUFunction(this, n"HandleOnLegGrabbed");
		CutieEar.OnWhipSlingableGrabbed.AddUFunction(this, n"HandleOnEarGrabbed");
		CutieLeg.GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleOnLegThrown");
		CutieEar.GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleOnEarThrown");
	}

	UFUNCTION()
	private void HandleOnLegThrown(UGravityWhipUserComponent UserComponent,
	                               UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                               FVector Impulse)
	{
		USkylineCutieSideInteractEventHandler::Trigger_OnLegThrown(this);
	}

	UFUNCTION()
	private void HandleOnEarThrown(UGravityWhipUserComponent UserComponent,
	                               UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                               FVector Impulse)
	{
		USkylineCutieSideInteractEventHandler::Trigger_OnEarThrown(this);
	}

	UFUNCTION()
	private void HandleOnEarGrabbed()
	{
		USkylineCutieSideInteractEventHandler::Trigger_OnEarRemoved(this);
		bEarGrabbed = true;
		if (bLegGrabbed)
			Online::UnlockAchievement(n"WhipEars");
	}

	UFUNCTION()
	private void HandleOnLegGrabbed()
	{
		USkylineCutieSideInteractEventHandler::Trigger_OnLegRemoved(this);
		bLegGrabbed = true;
		if (bEarGrabbed)
			Online::UnlockAchievement(n"WhipEars");
	}

	UFUNCTION()
	private void HandleStartGrabEar()
	{
		
	}

	UFUNCTION()
	private void HandleStartGrabLeg()
	{
		
	}
};