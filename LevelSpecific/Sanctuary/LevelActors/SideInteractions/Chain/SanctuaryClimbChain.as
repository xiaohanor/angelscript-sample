UCLASS(Abstract)
class ASanctuaryClimbChain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	APoleClimbActor PoleClimbActor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxConeRotComp;

	UPROPERTY(DefaultComponent, Attach = FauxConeRotComp)
	UFauxPhysicsForceComponent FauxForceComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPlayerWeightComp;
	default FauxPlayerWeightComp.PlayerForce = 50.0;

	UPROPERTY(EditInstanceOnly)
	int DesiredNumChainLinks = 10;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APoleClimbActor> PoleClimbingClass;

	UPROPERTY(EditAnywhere, Category = "Settings|Meshes")
	UStaticMesh ChainMesh;

	//Multiplier for the base calculated culling distances for the chain meshes
	UPROPERTY(EditInstanceOnly, Category = "Settings|Meshes")
	float MaxCullingDistMultiplier = 3.0;

	TArray<UStaticMeshComponent> ChainLinks;
	TArray<FHazeAcceleratedQuat> ChainLinksRotations;
	TArray<FVector> ChainLinkVelocities;

	TArray<FQuat> ChainLinksOGRelativeRotations;

	const float ChainLinkHeight = 60.0;

	TArray<AHazePlayerCharacter> ClimbingPlayers;
	bool bOptimizeAwayChainSimulation = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
		if (ChainMesh != nullptr)
		{
			ChainLinks.Reset();
			float32 BaseCullDistance = 0.0;
			for (int i = 0; i < DesiredNumChainLinks; ++i)
			{
				FString ChainLinkName = "ChainLink " + i;
				UStaticMeshComponent ChainLink =  UStaticMeshComponent::Create(this, FName(ChainLinkName));
				ChainLink.SetStaticMesh(ChainMesh);
				ChainLink.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				ChainLink.Mobility = EComponentMobility::Static;

				if (BaseCullDistance < KINDA_SMALL_NUMBER)
					BaseCullDistance = Editor::GetDefaultCullingDistance(ChainLink);
				ChainLink.SetCullDistance(BaseCullDistance * MaxCullingDistMultiplier);

				ChainLink.AttachToComponent(FauxConeRotComp);
				ChainLink.SetRelativeLocation(FVector(0.0, 0.0, -ChainLinkHeight * i));

				if (i % 2 == 1)
					ChainLink.SetRelativeRotation(FRotator(0.0, 90.0, 0.0));
				else
					ChainLink.SetRelativeRotation(FRotator(0.0, 0.0, 0.0));

				ChainLinks.Add(ChainLink);
			}
		}
		SetPoleHeight();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (PoleClimbingClass != nullptr && PoleClimbActor == nullptr)
		{
			FName PoleName = FName(GetName() + "_ClimbPole");
			PoleClimbActor = Cast<APoleClimbActor>(SpawnActor(PoleClimbingClass, ActorLocation, ActorRotation, PoleName));
			PoleClimbActor.RootComp.SetMobility(EComponentMobility::Movable);
			SetPoleHeight();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UStaticMeshComponent, ChainLinks);
		for (int i = 0; i < ChainLinks.Num(); ++i)
		{
			ChainLinksOGRelativeRotations.Add(ChainLinks[i].GetRelativeRotation().Quaternion());
			ChainLinksRotations.Add(FHazeAcceleratedQuat());
			ChainLinksRotations[i].SnapTo(ChainLinksOGRelativeRotations[i]);
		}

		SetPoleHeight();

		FauxForceComp.SetRelativeLocation(FVector(0.0, 0.0, - GetChainHeight() * 0.5));
		FauxForceComp.Force = FVector::UpVector * -2 * GetChainHeight();

		if (PoleClimbActor != nullptr)
		{
			PoleClimbActor.EnterZone.OnPlayerEnter.AddUFunction(this, n"PlayerEntered");
			PoleClimbActor.EnterZone.OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
			PoleClimbActor.OnEnterFinished.AddUFunction(this, n"PlayerAttached");
			PoleClimbActor.OnJumpOff.AddUFunction(this, n"PlayerDetach");
		}
	}

	UFUNCTION()
	private void PlayerEntered(AHazePlayerCharacter Player)
	{
		ClimbingPlayers.Add(Player);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		ClimbingPlayers.Remove(Player);
	}

	UFUNCTION()
	private void PlayerAttached(AHazePlayerCharacter Player, APoleClimbActor ThePoleClimbActor)
	{
		bOptimizeAwayChainSimulation = false;
		FVector Direction = ActorLocation - Player.ActorLocation;
		Direction.Z = 0.0;
		FauxConeRotComp.ApplyImpulse(Player.ActorLocation, Direction.GetSafeNormal() * 20.0);
	}

	UFUNCTION()
	private void PlayerDetach(AHazePlayerCharacter Player, APoleClimbActor SomePoleClimbActor, FVector JumpOutDirection)
	{
			FauxConeRotComp.ApplyImpulse(Player.ActorLocation, - JumpOutDirection.GetSafeNormal() * 30.0);
	}

	private void SetPoleHeight()
	{
		if (PoleClimbActor == nullptr)
		{
			TArray<AActor> AttachedActors;
			GetAttachedActors(AttachedActors);
			for (auto Attached : AttachedActors)
			{
				APoleClimbActor PoleClimby = Cast<APoleClimbActor>(Attached);
				if (PoleClimby != nullptr)
				{
					PoleClimbActor = PoleClimby;
					break;
				}
			}
		}

		if (PoleClimbActor != nullptr)
		{
			PoleClimbActor.AttachToComponent(FauxConeRotComp);
			float ChainHeight = GetChainHeight();
			FVector NewPoleLocation = - FVector::UpVector * ChainHeight;
			PoleClimbActor.SetActorRelativeLocation(NewPoleLocation);
			PoleClimbActor.SetNewHeight(ChainHeight - 40);
		}
	}

	float GetChainHeight() const
	{
		return ChainLinkHeight * DesiredNumChainLinks;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugCoordinateSystem(FauxConeRotComp.WorldLocation, FauxConeRotComp.WorldRotation, 150.0, 2.0);
		// Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 200.0, 5.0);
		// Debug::DrawDebugLine(ActorLocation, ActorLocation - ActorUpVector * GetChainHeight(), ColorDebug::Rose, 1.0);

		// Debug::DrawDebugLine(FauxConeRotComp.WorldLocation, FauxConeRotComp.WorldLocation - FauxConeRotComp.UpVector * GetChainHeight(), ColorDebug::Grape, 3.0, 0.0, true);
		// DangleChain(DeltaSeconds);

		ReactToClimbing(DeltaSeconds);
	}

	private void ReactToClimbing(float DeltaSeconds)
	{
		if (ChainLinks.Num() == 0)
			return;

		if (bOptimizeAwayChainSimulation)
			return;

		bool bAnyChainWantsSimulation = ClimbingPlayers.Num() > 0;

		const float AlignTreshold = 150.0;

		for (int iLink = 0; iLink < ChainLinks.Num(); ++iLink)
		{
			float CloseToPlayerAlpha = 0.0;
			FVector TowardsPlayerUp = FVector::UpVector;
			for (int iClimber = 0; iClimber < ClimbingPlayers.Num(); ++iClimber)
			{
				FVector AbovePlayer = ClimbingPlayers[iClimber].ActorUpVector * ClimbingPlayers[iClimber].CapsuleComponent.CapsuleHalfHeight * 1.0;
				FVector PlayerCompareLocation = ClimbingPlayers[iClimber].ActorLocation + AbovePlayer;
				float DistanceToLink = ChainLinks[iLink].WorldLocation.Distance(PlayerCompareLocation);
				if (DistanceToLink > AlignTreshold)
					continue;
				float Alpha = 1.0 - Math::Clamp(DistanceToLink / AlignTreshold, 0.0, 1.0);
				if (Alpha > CloseToPlayerAlpha)
				{
					CloseToPlayerAlpha = Alpha;
					float AbovePlayerSign = ClimbingPlayers[iClimber].ActorCenterLocation.Z > ChainLinks[iLink].WorldLocation.Z ? 1.0 : -1.0;
					FVector TowardsPlayerWorld = (ClimbingPlayers[iClimber].ActorCenterLocation - ChainLinks[iLink].WorldLocation).GetSafeNormal() * AbovePlayerSign;

					// Debug::DrawDebugSphere(PlayerCompareLocation, 10.0, 12, ColorDebug::Carrot);
					// Debug::DrawDebugSphere(ChainLinks[iLink].WorldLocation, 10.0, 12, ColorDebug::Cyan);
					// Debug::DrawDebugArrow(ChainLinks[iLink].WorldLocation, ChainLinks[iLink].WorldLocation + TowardsPlayerWorld * 50.0 * Alpha, 7.0, ColorDebug::Cyan, 1.0, 0.0, true);

					FVector TowardsPlayerLocal = ChainLinks[iLink].WorldTransform.InverseTransformVectorNoScale(TowardsPlayerWorld);

					TowardsPlayerUp = FVector::UpVector * 6.0 - TowardsPlayerLocal; //(FVector::UpVector - TowardsPlayerLocal).GetSafeNormal();
					TowardsPlayerUp = TowardsPlayerUp.GetSafeNormal();
				}
			}

			FVector DesiredLocalUp = Math::Lerp(FVector::UpVector, TowardsPlayerUp, CloseToPlayerAlpha);
			FQuat NewWorldRotation = FRotator::MakeFromZX(DesiredLocalUp, ChainLinksOGRelativeRotations[iLink].ForwardVector).Quaternion();

			const float SimulationTreshold = KINDA_SMALL_NUMBER * 10.0;
			if (ChainLinksRotations[iLink].VelocityAxisAngle.Size() > SimulationTreshold)
				bAnyChainWantsSimulation = true;

			ChainLinksRotations[iLink].SpringTo(NewWorldRotation, 100.0, 0.95, DeltaSeconds);
			ChainLinks[iLink].SetRelativeRotation(ChainLinksRotations[iLink].Value);
		}

		if (!bAnyChainWantsSimulation)
			bOptimizeAwayChainSimulation = true;
	}

	

	// private void DangleChain(float DeltaSeconds)
	// {
	// 	if (ChainLinks.Num() == 0)
	// 		return;

	// 	if (bOptimizeAwayChainSimulation)
	// 		return;

	// 	UStaticMeshComponent LowestDanglingLink = ChainLinks[0];
	// 	for (int iClimber = 0; iClimber < ClimbingPlayers.Num(); ++iClimber)
	// 	{
	// 		UStaticMeshComponent ClosestLink = ChainLinks[0];
	// 		float ClosestDistance = ClosestLink.WorldLocation.Distance(ClimbingPlayers[iClimber].ActorCenterLocation);
	// 		for (int iLink = 1; iLink < ChainLinks.Num(); ++iLink)
	// 		{
	// 			float DistanceToLink = ChainLinks[iLink].WorldLocation.Distance(ClimbingPlayers[iClimber].ActorCenterLocation);
	// 			if (DistanceToLink < ClosestDistance)
	// 			{
	// 				ClosestLink = ChainLinks[iLink];
	// 				ClosestDistance = DistanceToLink;
	// 			}
	// 		}

	// 		if (LowestDanglingLink.WorldLocation.Z > ClosestLink.WorldLocation.Z)
	// 			LowestDanglingLink = ClosestLink;
	// 	}

	// 	bool bAnyChainWantsSimulation = ClimbingPlayers.Num() > 0;
	// 	bool bPassedDanglingLink = false;

	// 	for (int iLink = 0; iLink < ChainLinks.Num(); ++iLink)
	// 	{
	// 		UStaticMeshComponent ChainLink = ChainLinks[iLink];

	// 		FVector DesiredWorldUp = FauxConeRotComp.UpVector;
	// 		if (LowestDanglingLink == ChainLink || bPassedDanglingLink)
	// 		{
	// 			bPassedDanglingLink = true;
	// 			DesiredWorldUp = FVector::UpVector;
	// 			Debug::DrawDebugArrow(ChainLink.WorldLocation, ChainLink.WorldLocation + DesiredWorldUp * 50.0, 7.0, ColorDebug::Cyan, 1.0, 0.0, true);
	// 		}

	// 		FQuat NewWorldRotation = FRotator::MakeFromZX(DesiredWorldUp, ChainLinksOGWorldRotations[iLink].ForwardVector).Quaternion();

	// 		const float SimulationTreshold = KINDA_SMALL_NUMBER * 10.0;
	// 		if (ChainLinksRotations[iLink].VelocityAxisAngle.Size() > SimulationTreshold)
	// 			bAnyChainWantsSimulation = true;

	// 		ChainLinksRotations[iLink].SpringTo(NewWorldRotation, 50.0, 0.95, DeltaSeconds);
	// 		ChainLinks[iLink].SetWorldRotation(ChainLinksRotations[iLink].Value);
	// 	}

	// 	if (!bAnyChainWantsSimulation)
	// 		bOptimizeAwayChainSimulation = true;

	// }

	// private void OldDangleChain(float DeltaSeconds)
	// {
	// 	if (ChainLinks.Num() == 0)
	// 		return;

	// 	if (bOptimizeAwayChainSimulation)
	// 		return;

	// 	UStaticMeshComponent LowestDanglingLink = ChainLinks[0];
	// 	for (int iClimber = 0; iClimber < ClimbingPlayers.Num(); ++iClimber)
	// 	{
	// 		UStaticMeshComponent ClosestLink = ChainLinks[0];
	// 		float ClosestDistance = ClosestLink.WorldLocation.Distance(ClimbingPlayers[iClimber].ActorCenterLocation);
	// 		for (int iLink = 1; iLink < ChainLinks.Num(); ++iLink)
	// 		{
	// 			float DistanceToLink = ChainLinks[iLink].WorldLocation.Distance(ClimbingPlayers[iClimber].ActorCenterLocation);
	// 			if (DistanceToLink < ClosestDistance)
	// 			{
	// 				ClosestLink = ChainLinks[iLink];
	// 				ClosestDistance = DistanceToLink;
	// 			}
	// 		}

	// 		if (LowestDanglingLink.WorldLocation.Z > ClosestLink.WorldLocation.Z)
	// 			LowestDanglingLink = ClosestLink;
	// 	}

	// 	bool bAnyChainWantsSimulation = ClimbingPlayers.Num() > 0;

	// 	bool bPassedDanglingLink = false;
	// 	for (int iLink = 0; iLink < ChainLinks.Num(); ++iLink)
	// 	{
	// 		UStaticMeshComponent ChainLink = ChainLinks[iLink];

	// 		FVector DesiredLocalUp = FVector::UpVector;
	// 		if (LowestDanglingLink == ChainLink || bPassedDanglingLink)
	// 		{
	// 			bPassedDanglingLink = true;
	// 			// DesiredRotation = FRotator::MakeFromZX(FVector::UpVector, ChainLinksOGRelativeRotations[iLink].ForwardVector).Quaternion();

	// 			FVector EndPointBelowLink = ChainLink.WorldLocation - FVector::UpVector * GetChainHeight();
	// 			FVector EndPointBelowActor = ActorLocation - FVector::UpVector * GetChainHeight();
	// 			float iFloatyLink = iLink;
	// 			float FloatyNumLinks = ChainLinks.Num() -1;
	// 			float ClimbedPercent = iFloatyLink / FloatyNumLinks;
	// 			FVector UsedLocation = Math::Lerp(EndPointBelowActor, EndPointBelowLink, ClimbedPercent);
	// 			FVector DesiredWorldUp = (ChainLink.WorldLocation - UsedLocation).GetSafeNormal();

	// 			DesiredLocalUp = ChainLink.WorldTransform.TransformVector(DesiredWorldUp);

	// 			// Debug::DrawDebugSphere(EndPointBelowActor, 10.0, 12, ColorDebug::Ruby);
	// 			// Debug::DrawDebugSphere(UsedLocation, 10.0, 12, ColorDebug::Carrot);
	// 			// Debug::DrawDebugArrow(ChainLink.WorldLocation, ChainLink.WorldLocation + DesiredWorldUp * 100.0, 5.0, ColorDebug::Cyan, 3.0, 0.0, true);
	// 		}

	// 		FQuat NewRelativeRotation = FRotator::MakeFromZX(DesiredLocalUp, FVector::ForwardVector).Quaternion() * ChainLinksOGWorldRotations[iLink];

	// 		//ChainLinksRotations[iLink].SpringTo(NewRelativeRotation, 10.0, 0.95, DeltaSeconds);
	// 		//ChainLinksRotations[iLink].AccelerateTo(NewRelativeRotation, 2.0, DeltaSeconds);

	// 		// Debug::DrawDebugString(ChainLink.WorldLocation, "" + ChainLinksRotations[iLink].VelocityAxisAngle.Size());

	// 		const float SimulationTreshold = KINDA_SMALL_NUMBER * 10.0;
	// 		if (ChainLinksRotations[iLink].VelocityAxisAngle.Size() > SimulationTreshold)
	// 			bAnyChainWantsSimulation = true;
	// 		ChainLinks[iLink].SetWorldRotation(ChainLinksRotations[iLink].Value);
	// 	}

	// 	if (!bAnyChainWantsSimulation)
	// 		bOptimizeAwayChainSimulation = true;
	// }
};