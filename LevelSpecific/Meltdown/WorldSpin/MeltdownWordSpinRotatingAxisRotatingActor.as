class AMeltdownWordSpinRotatingAxisRotatingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxRotate;
	default FauxRotate.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = FauxRotate)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent FauxResponseComp;

	UPROPERTY(EditAnywhere)
	AMeltdownWorldSpinManager Manager;

	float Spindirection;

	bool bForcefeedbackAllowed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}


	UFUNCTION(BlueprintCallable)
	void ApplyGravity()
	{
		FauxWeightComp.bApplyGravity = true;
	}

	UFUNCTION(BlueprintCallable)
	void DisableGravity()
	{
		FauxWeightComp.bApplyGravity = false;
	}

	UFUNCTION(BlueprintEvent)
	void ActivateLeftHatch()
	{
		UMeltdownWorldSpinRotatingAxisEventHandler::Trigger_OnActivateLeftHatch(this);
	}

	UFUNCTION(BlueprintEvent)
	void ActivateRightHatch()
	{
		UMeltdownWorldSpinRotatingAxisEventHandler::Trigger_OnActivateRightHatch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		float Distance = Game::Zoe.GetDistanceTo(this);
		if (Distance < 5000.0)
			FauxRotate.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		else
			FauxRotate.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
		
			if(Manager == nullptr)
				return;

		Spindirection = Manager.WorldSpinRotation.UpVector.Y;

		if(Spindirection < -0.2)
			ActivateLeftHatch();

		if(Spindirection > 0.2)
			ActivateRightHatch();
	}
};

UCLASS(Abstract)
class UMeltdownWorldSpinRotatingAxisEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateLeftHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateRightHatch() {}

};