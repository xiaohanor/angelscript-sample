class AIslandSidescrollerBlockingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UStaticMeshComponent DoorMeshComp;
	default DoorMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UBoxComponent BoxCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSidescrollerBlockingDoorDummyComponent DummyComp;
#endif

	default ActorTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector OpenedOffset = FVector(0, 0, 300);

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector CollisionBoxExtents = FVector(10, 318, 220);

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartOpen = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveDuration = 0.6;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	ABothPlayerTrigger BothPlayerTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	ABothPlayerTrigger BothPlayerTriggerOpen;

	FVector LastRestLocation;
	FVector TargetLocation;
	float TimeStartedMoving;

	bool bIsOpen;

	bool bHasBeenActivated;
	bool bHasBeenDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		bIsOpen = bStartOpen;

		if (bStartOpen)
			BP_Blocker(true);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bStartOpen)
			MovingRoot.WorldLocation = OpenedLocation;
		else
			MovingRoot.WorldLocation = ClosedLocation;

		// FVector NewBoxExtents = FVector(CollisionBoxExtents.X * DoorMeshComp.WorldScale.X
		// 	, CollisionBoxExtents.Y * DoorMeshComp.WorldScale.Y
		// 	, CollisionBoxExtents.Z * DoorMeshComp.WorldScale.Z);
		// BoxCollision.SetBoxExtent(NewBoxExtents, false);

		// FVector NewRelativeLocation = FVector(0, 0, NewBoxExtents.Z);
		// BoxCollision.SetRelativeLocation(NewRelativeLocation);

		if (BothPlayerTrigger != nullptr)
			BothPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"ActivateBlocker");

		if (BothPlayerTriggerOpen != nullptr)
			BothPlayerTriggerOpen.OnBothPlayersInside.AddUFunction(this, n"DeactivateBlocker");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float MoveAlpha = Time::GetGameTimeSince(TimeStartedMoving) / MoveDuration;
		const FVector DoorLocation = Math::Lerp(LastRestLocation, TargetLocation, Math::EaseInOut(0.0, 1.0, MoveAlpha, 2.0));
		MovingRoot.SetWorldLocation(DoorLocation);

		if(MoveAlpha >= 1.0)
			SetActorTickEnabled(false);
	}

	FVector GetOpenedLocation() const property
	{
		return ActorLocation + ActorTransform.TransformVectorNoScale(OpenedOffset);
	}

	FVector GetClosedLocation() const property
	{
		return ActorLocation;
	}

	UFUNCTION()
	void ActivateBlocker()
	{
		if (!bIsOpen)
			return;

		if (bHasBeenActivated)
			return;

		bHasBeenActivated = true;
		// bHasBeenDeactivated = true;
		// bIsOpen = true;
		BP_CloseDoorByTrigger();
	}

	UFUNCTION()
	void DeactivateBlocker()
	{
		if (bIsOpen)
			return;

		if (bHasBeenDeactivated)
			return;
		
		bHasBeenDeactivated = true;
		// bHasBeenActivated = true;
		// bIsOpen = false;
		BP_OpenDoorByTrigger();

		// PrintToScreen("Should OPEN door!!!", 10);
	}

	UFUNCTION(BlueprintCallable)
	void StartOpeningDoor()
	{
		if(bIsOpen)
			return;

		LastRestLocation = ClosedLocation;
		TargetLocation = OpenedLocation;
		TimeStartedMoving = Time::GameTimeSeconds;
		SetActorTickEnabled(true);

		BoxCollision.AttachToComponent(MovingRoot);

		bIsOpen = true;

		BP_Blocker(true);
		UIslandSidescrollerBlockingDoorEventHandler::Trigger_OnStartOpen(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartClosingDoor()
	{
		if(!bIsOpen)
			return;

		LastRestLocation = OpenedLocation;
		TargetLocation = ClosedLocation;
		TimeStartedMoving = Time::GameTimeSeconds;
		SetActorTickEnabled(true);

		BoxCollision.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		BoxCollision.WorldLocation = TargetLocation + DoorMeshComp.UpVector * BoxCollision.BoxExtent.Z;

		bIsOpen = false;
		BP_Blocker(false);
		UIslandSidescrollerBlockingDoorEventHandler::Trigger_OnStartClosing(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Blocker(bool bOpen)
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenDoorByTrigger(){}

	UFUNCTION(BlueprintEvent)
	void BP_CloseDoorByTrigger(){}

};

#if EDITOR
class UIslandSidescrollerBlockingDoorDummyComponent : UActorComponent {};
class UIslandSidescrollerBlockingDoorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSidescrollerBlockingDoorDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandSidescrollerBlockingDoorDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		if(Comp.Owner == nullptr)
			return;

		auto Door = Cast<AIslandSidescrollerBlockingDoor>(Comp.Owner);
		if(Door == nullptr)
			return;
		
		FVector BoundsLocation;
		FVector BoundsExtent;
		Door.GetActorLocalBounds(true, BoundsLocation, BoundsExtent, false);	

		BoundsExtent *= Door.ActorScale3D;

		if(Door.bStartOpen)
		{
			FVector TargetLocation = Door.ActorTransform.TransformPositionNoScale(BoundsLocation) - Door.ActorTransform.TransformVectorNoScale(Door.OpenedOffset);
			DrawWireBox(TargetLocation, BoundsExtent, Comp.Owner.ActorQuat, FLinearColor::LucBlue, 5, false);
			DrawWorldString("Closed Location", TargetLocation, FLinearColor::LucBlue);
		}
		else
		{
			FVector TargetLocation = Door.ActorTransform.TransformPositionNoScale(BoundsLocation) + Door.ActorTransform.TransformVectorNoScale(Door.OpenedOffset);
			DrawWireBox(TargetLocation, BoundsExtent, Comp.Owner.ActorQuat, FLinearColor::Purple, 5, false);
			DrawWorldString("Opened Location", TargetLocation, FLinearColor::Purple);
		}
	}
}
#endif