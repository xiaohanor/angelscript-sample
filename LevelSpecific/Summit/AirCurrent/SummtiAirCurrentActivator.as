event void FSummitAirCurrentActivatorGrabbed();
event void FSummitAirCurrentActivatorActivated();

class ASummitAirCurrentActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// bool bActive = true;
	bool bGrabbed;
	// AHazeActor Grabber;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"SummitAirCurrentActivatorInteractionCapability";
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent Cable;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent AirCurrentCable;

	UPROPERTY(EditAnywhere)
	float ActivationDistance = 1000;

	UPROPERTY()
	FSummitAirCurrentActivatorGrabbed OnGrabbed;
	UPROPERTY()
	FSummitAirCurrentActivatorActivated OnActivated;

	FTransform AttachmentBone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cable.SetAttachEndTo(this, n"CableHandle");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bGrabbed)
			Cable.CableLength = AttachmentBone.Location.Distance(Root.WorldLocation);
		else if (!bGrabbed && Cable.CableLength > 0)
			Cable.CableLength -= (250 * DeltaSeconds);
	}

	void EnterInteraction(AHazePlayerCharacter Interactor)
	{
		OnGrabbed.Broadcast();

		auto DragonMesh = UPlayerTeenDragonComponent::Get(Interactor).DragonMesh;

		Cable.bAttachEnd = true;
		AttachmentBone = DragonMesh.GetSocketTransform(n"Jaw");
		Cable.SetAttachEndToComponent(DragonMesh, n"Jaw");
		Cable.EndLocation = FVector::ZeroVector;

		bGrabbed = true;
	}

	void ExitInteraction()
	{
		FVector CableEndLocation = AttachmentBone.Location;
		Cable.CableLength = CableEndLocation.Distance(Root.WorldLocation);
		Cable.bAttachEnd = false;

		bGrabbed = false;
	}

	void ActivateWindCurrent()
	{
		OnActivated.Broadcast();
		AirCurrentCable.bAttachEnd = false;
		ExitInteraction();
	}
}