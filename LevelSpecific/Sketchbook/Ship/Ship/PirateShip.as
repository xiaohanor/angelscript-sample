event void FPirateShipOnStartSailing();
event void FPirateShipOnStartSinking();
event void FPirateShipOnSunk();

UCLASS(Abstract)
class APirateShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HullMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MainMastRoot;

	UPROPERTY(DefaultComponent, Attach = MainMastRoot)
	USceneComponent MainMastBoomRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrontMastRoot;

	UPROPERTY(DefaultComponent, Attach = FrontMastRoot)
	USceneComponent FrontMastBoomRoot;

	UPROPERTY(DefaultComponent)
	protected UPirateWaterHeightComponent WaterHeightComp;

	UPROPERTY(DefaultComponent)
	protected UPirateShipDeckComponent DeckComp;

	UPROPERTY(DefaultComponent)
	protected UPirateShipDepenetrationComponent DepenetrationComp;

	UPROPERTY(DefaultComponent)
	protected UPirateShipMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	protected UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	protected UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	protected UEnvironmentCableComponent FrontSailLeftRopeComp;

	UPROPERTY(DefaultComponent)
	protected UEnvironmentCableComponent FrontSailRightRopeComp;

	UPROPERTY(DefaultComponent)
	protected UEnvironmentCableComponent MainSailLeftRopeComp;

	UPROPERTY(DefaultComponent)
	protected UEnvironmentCableComponent MainSailRightRopeComp;

	UPROPERTY(DefaultComponent)
	protected UHazeRequestCapabilityOnPlayerComponent RequestComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	protected UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	APirateShipHelm Helm;

	// UPROPERTY(EditInstanceOnly)
	// TArray<APirateShipCannon> Cannons;

	UPROPERTY(EditInstanceOnly)
	TArray<APirateShipSail> Sails;

	UPROPERTY(EditInstanceOnly)
	TArray<APirateShipMooring> Moorings;

	// UPROPERTY(EditInstanceOnly)
	// APirateShipPlank Plank;

	// UPROPERTY(EditDefaultsOnly)
	// TSubclassOf<APirateShipDamage> DamageClass;

	UPROPERTY()
	FPirateShipOnStartSailing OnStartSailing;

	UPROPERTY()
	FPirateShipOnStartSinking OnStartSinking;

	UPROPERTY()
	FPirateShipOnSunk OnSunk;

	//TMap<int, APirateShipDamage> CurrentDamages;
	private TArray<UEnvironmentCableComponent> RopeComponents;

	FHazeAcceleratedFloat AccSailYaw;

	private bool bIsSinking = false;
	private bool bHasSunk = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector HorizontalForward = ActorForwardVector.VectorPlaneProject(FVector::UpVector);
		FVector UpVector = WaterHeightComp.GetWaterUpVector();
		FQuat WaterRotation = FQuat::MakeFromZX(UpVector, HorizontalForward);
		MoveComp.AccWaterRotation.SnapTo(WaterRotation);

		AccSailYaw.Value = GetMastRelativeYaw();

		FrontSailLeftRopeComp.SetAttachEndTo(Sails[0], n"RopeTetherLeft");
		FrontSailLeftRopeComp.EndLocation = FVector::ZeroVector;
		FrontSailRightRopeComp.SetAttachEndTo(Sails[0], n"RopeTetherRight");
		FrontSailRightRopeComp.EndLocation = FVector::ZeroVector;

		MainSailLeftRopeComp.SetAttachEndTo(Sails[1], n"RopeTetherLeft");
		MainSailLeftRopeComp.EndLocation = FVector::ZeroVector;
		MainSailRightRopeComp.SetAttachEndTo(Sails[1], n"RopeTetherRight");
		MainSailRightRopeComp.EndLocation = FVector::ZeroVector;

		RopeComponents.Reset();
		GetComponentsByClass(RopeComponents);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateRopeLengths();
	}

	UFUNCTION(BlueprintCallable)
	void StartPirateSheets()
	{
		for(auto Player : Game::Players)
			RequestComp.StartInitialSheetsAndCapabilities(Player, this);

		CapabilityComp.StartInitialStoppedSheets(this);

		StartSailing();
	}

	UFUNCTION(BlueprintCallable)
	void StopPirateSheets()
	{
		for(auto Player : Game::Players)
			RequestComp.StopInitialSheetsAndCapabilities(Player, this);

		CapabilityComp.StopInitialStoppedSheets(this);
	}

	private void UpdateRopeLengths()
	{
		for(auto Rope : RopeComponents)
		{
			Rope.CableLength = Rope.GetStartParticleLocation().Distance(Rope.GetEndParticleLocation());
		}
	}

	private float GetMastRelativeYaw() const
	{
		FVector SplineForward = FVector::ForwardVector; //Pirate::GetSplineDirection(ActorLocation);
		FVector RelativeSplineForward = ActorTransform.InverseTransformVectorNoScale(SplineForward);
		FRotator RelativeRotation = FRotator::MakeFromX(RelativeSplineForward);

		return Math::Clamp(RelativeRotation.Yaw, -Pirate::Ship::MaxMastRotateAmount, Pirate::Ship::MaxMastRotateAmount);
	}

	void AngleSails(float DeltaTime)
	{
		AccSailYaw.AccelerateTo(GetMastRelativeYaw(), Pirate::Ship::MastRotateDuration, DeltaTime);
		MainMastBoomRoot.SetRelativeRotation(FRotator(0, AccSailYaw.Value, 0));
		FrontMastBoomRoot.SetRelativeRotation(FRotator(0, AccSailYaw.Value, 0));
	}

	void StartSinking()
	{
		if(bIsSinking)
			return;

		bIsSinking = true;
		OnStartSinking.Broadcast();
		DisableAllInteractions();
	}

	private void DisableAllInteractions()
	{
		TArray<AActor> ActorsToDisableOn;
		ActorsToDisableOn.Add(this);
		GetAttachedActors(ActorsToDisableOn, false, true);

		for(auto Actor : ActorsToDisableOn)
		{
			APerchSpline PerchSpline = Cast<APerchSpline>(Actor);
			if(PerchSpline != nullptr)
			{
				PerchSpline.DisablePerchSpline(this);
				continue;
			}

			AGrapplePoint GrapplePoint = Cast<AGrapplePoint>(Actor);
			if(GrapplePoint != nullptr)
			{
				GrapplePoint.GrapplePoint.Disable(this);
				continue;
			}

			APoleClimbActor PoleClimb = Cast<APoleClimbActor>(Actor);
			if(PoleClimb != nullptr)
			{
				PoleClimb.DisablePoleActor();
			}

			TArray<UInteractionComponent> InteractionComponents;
			Actor.GetComponentsByClass(InteractionComponents);

			for(auto InteractionComponent : InteractionComponents)
			{
				InteractionComponent.KickAnyPlayerOutOfInteraction();
				InteractionComponent.Disable(this);
			}
		}
	}

	bool IsSinking() const
	{
		return bIsSinking;
	}

	void FinishSinking()
	{
		check(bIsSinking);
		if(bHasSunk)
			return;

		bHasSunk = true;
		OnSunk.Broadcast();
	}

	bool HasSunk() const
	{
		return bHasSunk;
	}

	bool TrySpawnDamage(FVector Location)
	{
		// int ClosestPointIndex = DeckComp.GetClosestTargetPointIndexTo(Location);
		// if(CurrentDamages.Contains(ClosestPointIndex))
		// 	return false;

		// FVector TargetPointLocation = DeckComp.GetWorldTargetPointLocationFromIndex(ClosestPointIndex);

		// FQuat Rotation = FQuat(ActorUpVector, Math::Rand());
		// APirateShipDamage Damage = SpawnActor(DamageClass, TargetPointLocation, Rotation.Rotator(), NAME_None, true);
		// Damage.Ship = this;
		// Damage.TargetPointIndex = ClosestPointIndex;
		// Damage.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		// CurrentDamages.Add(ClosestPointIndex, Damage);

		// FinishSpawningActor(Damage);

		return true;
	}

	// void RemoveDamage(APirateShipDamage Damage)
	// {
	// 	check(CurrentDamages.Contains(Damage.TargetPointIndex));
	// 	CurrentDamages.Remove(Damage.TargetPointIndex);
	// }

	bool CanShipMove() const
	{
		if(!HaveAllMooringsBeenRemoved())
			return false;

		if(!HaveSailsBeenRolledDown())
			return false;

		return true;
	}

	bool HaveAllMooringsBeenRemoved() const
	{
		for(auto Mooring : Moorings)
		{
			if(Mooring.IsMoored())
				return false;
		}

		return true;
	}

	bool HaveSailsBeenRolledDown() const
	{
		for(auto Sail : Sails)
		{
			if(!Sail.IsRolledDown())
				return false;
		}

		return true;
	}

	float GetTurnAmount() const
	{
		return Helm.GetTurnAmount();
	}

	FVector GetRandomUnoccupiedTargetPointOnDeck() const
	{
		return FVector::ZeroVector;
		// TArray<int> UnoccupiedIndices;
		// for(int i = 0; i < CurrentDamages.Num(); i++)
		// {
		// 	if(CurrentDamages.Contains(i))
		// 		continue;

		// 	UnoccupiedIndices.Add(i);
		// }

		// if(UnoccupiedIndices.IsEmpty())
		// 	return DeckComp.GetCenterOfDeck();

		// int Index = UnoccupiedIndices[Math::RandRange(0, UnoccupiedIndices.Num() - 1)];
		// return DeckComp.GetWorldTargetPointLocationFromIndex(Index);
	}
	
	FVector GetCenterOfDeck() const
	{
		return DeckComp.GetCenterOfDeck();
	}

	void StartSailing()
	{
		for(auto Mooring : Moorings)
		{
			Mooring.UnMoor();
		}

		for(auto Sail : Sails)
		{
			Sail.RollDownSail();
		}
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void DevStartSailing()
	{
		StartSailing();
	}

	UFUNCTION(DevFunction)
	void SpawnRandomDamage()
	{
		TrySpawnDamage(DeckComp.GetRandomWorldTargetPoint());
	}

	UFUNCTION(DevFunction)
	void KillMio()
	{
		Game::Mio.KillPlayer();
	}

	UFUNCTION(DevFunction)
	void KillZoe()
	{
		Game::Zoe.KillPlayer();
	}
#endif
};