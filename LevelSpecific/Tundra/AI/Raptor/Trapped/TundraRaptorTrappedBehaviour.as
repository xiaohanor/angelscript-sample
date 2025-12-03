
class UTundraRaptorTrappedBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	ATundraRaptor Raptor;
	bool bTrapped;
	FVector TrapLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Raptor = Cast<ATundraRaptor>(Owner);

		UTundraGrabberVinesResponseComponent GrabberComp = UTundraGrabberVinesResponseComponent::GetOrCreate(Owner);
		GrabberComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GrabberComp.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION()
	private void OnReleased(FTundraGrabberVinesReleasedData Data)
	{
		bTrapped = false;
	}

	UFUNCTION()
	private void OnGrabbed(FTundraGrabberVinesGrabbedData Data)
	{
		TrapLocation = Data.Grabber.ActorLocation;
		bTrapped = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!bTrapped)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if(!bTrapped)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		//AnimComp.RequestFeature(FeatureTagStinger::Charge, SubTagStingerCharge::ChargeTelegraph, EBasicBehaviourPriority::Medium, this);
		
		Raptor.SetActorLocation(FVector(TrapLocation.X, TrapLocation.Y, Raptor.ActorLocation.Z));
		Raptor.MeshOffsetComponent.SetRelativeLocation(FVector(0, 0, -300));
		Raptor.Mesh.AddComponentTickBlocker(this);

		Owner.BlockCapabilities(n"FlyingMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Raptor.MeshOffsetComponent.SetRelativeLocation(FVector(0, 0, 0));
		Raptor.Mesh.RemoveComponentTickBlocker(this);
		Owner.UnblockCapabilities(n"FlyingMovement", this);
	}
}