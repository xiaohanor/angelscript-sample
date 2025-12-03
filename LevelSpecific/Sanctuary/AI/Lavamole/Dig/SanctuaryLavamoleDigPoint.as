class ASanctuaryLavamoleDigPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionMeshComp;

	AAISanctuaryLavamole Occupant = nullptr;
	ASanctuaryLavamoleGeyser Geyser = nullptr;

	// UPROPERTY(DefaultComponent)
	USphereComponent OverlapPlayerTrigger;
	// default OverlapPlayerTrigger.SetSphereRadius(50.0, false);

	TArray<UPrimitiveComponent> OverlappedCentipedeParts;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(3.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 150.0);
#endif	

	UPROPERTY(EditInstanceOnly)
	bool bSafeDigPoint = false;

	bool HasOccupant()
	{
		if (OverlappedCentipedeParts.Num() > 0)
			return true;
		bool bHasActiveGeyser = Geyser != nullptr && Geyser.State != ESanctuaryLavamoleGeyserState::Inactive;
		return Occupant != nullptr || bHasActiveGeyser;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(SanctuaryLavamoleTags::DigPointTeam);
		//OverlapPlayerTrigger = Cast<USphereComponent>(GetOrCreateComponent(USphereComponent, n"OverlapPlayerComp"));
		// OverlapPlayerTrigger.
		if (OverlapPlayerTrigger != nullptr)
		{
			OverlapPlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerOverlap");
			OverlapPlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");
		}

		TArray<AActor> Attacheds;
		GetAttachedActors(Attacheds);
		for (int iActor = 0; iActor < Attacheds.Num(); ++iActor)
		{
			ASanctuaryLavamoleGeyser AttachedGeyser = Cast<ASanctuaryLavamoleGeyser>(Attacheds[iActor]);
			if (AttachedGeyser != nullptr)
			{
				Geyser = AttachedGeyser;
				break;
			}
		}

		SetHoleCollisionEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(SanctuaryLavamoleTags::DigPointTeam);
	}

	UFUNCTION()
	private void HandleTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (IsValid(OtherActor))
		{
			ACentipede Cento = Cast<ACentipede>(OtherActor);
			if (IsValid(Cento) && !OverlappedCentipedeParts.Contains(OtherComp))
				OverlappedCentipedeParts.Add(OtherComp);
		}
	}

	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (IsValid(OtherActor))
		{
			ACentipede Cento = Cast<ACentipede>(OtherActor);
			if (IsValid(Cento) && OverlappedCentipedeParts.Contains(OtherComp))
				OverlappedCentipedeParts.Remove(OtherComp);
		}
	}

	UFUNCTION()
	void SetHoleCollisionEnabled(bool bCollisionEnabled)
	{
		if (bCollisionEnabled)
			CollisionMeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		else
			CollisionMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
}