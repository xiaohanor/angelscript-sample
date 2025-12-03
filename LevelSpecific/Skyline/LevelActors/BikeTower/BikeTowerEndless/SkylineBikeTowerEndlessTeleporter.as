event void FSkylineBikeTowerEndlessTeleporter(AHazePlayerCharacter Player, AGravityBikeFree GravityBikeFree);

class ASkylineBikeTowerEndlessTeleporter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;
	default Trigger.bGenerateOverlapEvents = true;
	default Trigger.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default Trigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Overlap);
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default Trigger.BoxExtent = FVector(500.0, 2000.0, 1000.0);

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ASkylineBikeTowerEndlessTeleporter> LinkedTeleporter;

	UPROPERTY()
	FSkylineBikeTowerEndlessTeleporter OnTeleported;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (LinkedTeleporter == nullptr)
			return;

		auto GravityBikeFree = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBikeFree == nullptr)
			return;

		if(!GravityBikeFree.HasControl())
			return;

		CrumbTeleport(GravityBikeFree);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTeleport(AGravityBikeFree GravityBike)
	{
		FTransform RelativeTransform = GravityBike.ActorTransform.GetRelativeTransform(ActorTransform);
		FTransform DestinationTransform = RelativeTransform * LinkedTeleporter.Get().ActorTransform;

		// Transform actor velocity
		FVector RelativeVelocity = ActorTransform.InverseTransformVectorNoScale(GravityBike.ActorVelocity);
//		HazeActor.ActorTransform = DestinationTransform;
		GravityBike.TeleportActor(DestinationTransform.Location, DestinationTransform.Rotator(), this, false);

		GravityBike.ActorVelocity = LinkedTeleporter.Get().ActorTransform.TransformVectorNoScale(RelativeVelocity);

		if(GravityBike.HasControl())
		{
			auto CameraUserComp = UCameraUserComponent::Get(GravityBike.GetDriver());

			if(CameraUserComp != nullptr)
			{
				FRotator RelativeRotation = ActorTransform.InverseTransformRotation(CameraUserComp.GetDesiredRotation());
				FRotator DestinationRotation = LinkedTeleporter.Get().ActorTransform.TransformRotation(RelativeRotation);
				CameraUserComp.SnapCamera(DestinationRotation.ForwardVector);
				CameraUserComp.SetDesiredRotation(DestinationRotation, this);
			}

			auto BikeCameraDataComp = UGravityBikeFreeCameraDataComponent::Get(GravityBike.GetDriver());
			if(BikeCameraDataComp != nullptr)
			{
				FRotator RelativeRotation = ActorTransform.InverseTransformRotation(BikeCameraDataComp.AccCameraRotation.Value.Rotator());
				FRotator DestinationRotation = LinkedTeleporter.Get().ActorTransform.TransformRotation(RelativeRotation);

	//			BikeCameraDataComp.AccCameraRotation.SnapTo(FQuat::Identity);
				BikeCameraDataComp.AccCameraRotation.SnapTo(DestinationRotation.Quaternion());
	//			BikeCameraDataComp.AccCameraRotation.SnapTo(LinkedTeleporter.Get().ActorQuat);

				BikeCameraDataComp.ApplyDesiredRotation(this, true);
			}
		}

		GravityBike.BlockCapabilities(CapabilityTags::Movement, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Movement, this);
		GravityBike.BlockCapabilities(CapabilityTags::Camera, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Camera, this);

		AHazePlayerCharacter Player = GravityBike.GetDriver();
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Camera, this);
		Player.UnblockCapabilities(CapabilityTags::Camera, this);

		LinkedTeleporter.Get().OnTeleported.Broadcast(Player, GravityBike);
	}
};