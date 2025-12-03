class ASkylineFacadeTeleportActor : AHazeActor
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
//	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default Trigger.BoxExtent = FVector(500.0, 2000.0, 1000.0);

	UPROPERTY(EditAnywhere)
	TSoftObjectPtr<ASkylineFacadeTeleportActor> LinkedTeleporter;

	bool bIndicatorBlocked = false;

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

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.HasControl())
			return;

		CrumbTeleportPlayer(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTeleportPlayer(AHazePlayerCharacter Player)
	{
		if (!bIndicatorBlocked)
		{
			for (auto P : Game::Players)
			{
				P.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
				bIndicatorBlocked = true;
			}
		}

		auto HazeActor = Cast<AHazeActor>(Player);

		FTransform RelativeTransform = HazeActor.ActorTransform.GetRelativeTransform(ActorTransform);
		FTransform DestinationTransform = RelativeTransform * LinkedTeleporter.Get().ActorTransform;

		// Transform actor velocity
		FVector RelativeVelocity = ActorTransform.InverseTransformVectorNoScale(HazeActor.ActorVelocity);
		FVector RelativeGravity = ActorTransform.InverseTransformVectorNoScale(Player.GetGravityDirection());
//		HazeActor.ActorTransform = DestinationTransform;
		Player.OverrideGravityDirection(LinkedTeleporter.Get().ActorTransform.TransformVectorNoScale(RelativeGravity).GetSafeNormal(), this, EInstigatePriority::High);
		HazeActor.TeleportActor(DestinationTransform.Location, DestinationTransform.Rotator(), this, false);
		HazeActor.ActorVelocity = LinkedTeleporter.Get().ActorTransform.TransformVectorNoScale(RelativeVelocity);

		auto CameraUserComp = UCameraUserComponent::Get(Player);

		if(CameraUserComp != nullptr)
		{
			FRotator RelativeRotation = ActorTransform.InverseTransformRotation(CameraUserComp.GetDesiredRotation());
			FRotator DestinationRotation = LinkedTeleporter.Get().ActorTransform.TransformRotation(RelativeRotation);
			CameraUserComp.SnapCamera(DestinationRotation.ForwardVector);
			CameraUserComp.SetDesiredRotation(DestinationRotation, this);
		}

		HazeActor.BlockCapabilities(CapabilityTags::Movement, this);
		HazeActor.UnblockCapabilities(CapabilityTags::Movement, this);
		HazeActor.BlockCapabilities(CapabilityTags::Camera, this);
		HazeActor.UnblockCapabilities(CapabilityTags::Camera, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Camera, this);
		Player.UnblockCapabilities(CapabilityTags::Camera, this);
	}

	UFUNCTION()
	void RemoveGravityOverride()
	{
		for (auto Player : Game::Players)
		{
			Player.ClearGravityDirectionOverride(this);
			Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		}
	}
};