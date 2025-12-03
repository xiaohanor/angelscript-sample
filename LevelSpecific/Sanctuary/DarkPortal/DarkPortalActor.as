enum EDarkPortalState
{
	Absorb,
	Launch,
	Settle,
	Recall
}

struct FDarkPortalTargetData
{
	USceneComponent SceneComponent = nullptr;
	FName SocketName = NAME_None;
	FVector RelativeLocation = FVector::ZeroVector;
	FVector RelativeNormal = FVector::ForwardVector;
	bool bObstructed = false;
	bool bSpecialCasePullBecauseTargetCanRotate = false;

	FDarkPortalTargetData(USceneComponent InSceneComponent,
		FName InSocketName,
		FVector InWorldLocation,
		FVector InWorldNormal,
		bool bInObstructed = false)
	{
		SceneComponent = InSceneComponent;
		SocketName = InSocketName;
		RelativeLocation = InWorldLocation;
		RelativeNormal = InWorldNormal;
		bObstructed = bInObstructed;

		if (SceneComponent != nullptr)
		{
			RelativeLocation = SceneComponent
				.GetSocketTransform(SocketName)
				.InverseTransformPositionNoScale(RelativeLocation);

			RelativeNormal = SceneComponent
				.GetSocketTransform(SocketName)
				.InverseTransformVector(InWorldNormal);
		}
	}

	FVector GetWorldLocation() const property
	{
		if (SceneComponent != nullptr)
		{
			return SceneComponent.
				GetSocketTransform(SocketName).
				TransformPositionNoScale(RelativeLocation);
		}

		return RelativeLocation;
	}

	FVector GetWorldNormal() const property
	{
		if (SceneComponent != nullptr)
		{
			return SceneComponent
				.GetSocketTransform(SocketName)
				.TransformVector(RelativeNormal);
		}

		return RelativeNormal;
	}

	FTransform GetWorldTransform() const property
	{
		return FTransform(
			WorldNormal.Rotation(),
			WorldLocation
		);
	}

	bool IsValid() const
	{
		if (SceneComponent == nullptr)
			return false;
		if (SceneComponent.IsBeingDestroyed())
			return false;
		
		return true;
	}
}

struct FDarkPortalUserGrab
{
	AActor Actor = nullptr;
	UDarkPortalResponseComponent ResponseComponent = nullptr;
	TArray<UDarkPortalTargetComponent> TargetComponents;

	float Timestamp = 0.0;
	bool bHasTriggeredResponse = false;
}

class ADarkPortalActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	// Note that launch and settle functionality is handled by companion
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"DarkPortalRecallCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"DarkPortalGrabCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"DarkPortalArmEffectCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"DarkPortalPullCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"DarkPortalPlacementValidationCapability");

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponse;
	default LightBirdResponse.bExclusiveAttachedIllumination = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Portal")
	UNiagaraSystem ArmEffect;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	EDarkPortalState State = EDarkPortalState::Absorb;
	UPROPERTY(NotVisible, BlueprintReadOnly)
	float StateTimestamp = 0.0;

	EDarkPortalState PreviousState = EDarkPortalState::Absorb;

	AHazePlayerCharacter Player;
	bool bPlayerWantsGrab;
	bool bIsGrabActive;
	bool bForcedVisible;
	bool bIsMegaPortal;
	bool bDespawnRequested;
	float ReleaseRequestTimestamp;
	float LastGrabTime = -BIG_NUMBER;

	TArray<FDarkPortalUserGrab> Grabs;
	UDarkPortalResponseComponent AttachResponse;
	TArray<UDarkPortalArmComponent> SpawnedArms;
	FDarkPortalTargetData TargetData;
	
	// Set to true to ignore conditions for grabbing
	bool bForcedGrabs = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Outline::AddToPlayerOutlineActor(this, Game::Zoe, this, EInstigatePriority::Normal); // Outline temp fix
	}

	void Fire(FDarkPortalTargetData InTargetData)
	{
		TargetData = InTargetData;
		SetState(EDarkPortalState::Launch);
	}

	void Recall()
	{
		TargetData = FDarkPortalTargetData();
		SetState(EDarkPortalState::Recall);
	}

	void InstantRecall()
	{
		FDarkPortalRecallEventData RecallParams;
		RecallParams.PortalTransform = ActorTransform;
		UDarkPortalEventHandler::Trigger_Recalled(this, RecallParams);

		TargetData = FDarkPortalTargetData();
		AttachPortal(Player.Mesh.GetSocketTransform(DarkPortal::Absorb::AttachSocket), Player.Mesh, DarkPortal::Absorb::AttachSocket);
		SetState(EDarkPortalState::Absorb);

		UDarkPortalEventHandler::Trigger_Absorbed(this);
	}

	void SetState(EDarkPortalState InState)
	{
		PreviousState = State;
		State = InState;
		StateTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(CrumbFunction)
	void CrumbGrab(UDarkPortalTargetComponent TargetComponent)
	{
		Grab(TargetComponent);
	}

	void Grab(UDarkPortalTargetComponent TargetComponent)
	{
		//PrintToScreen("GRab");
		if (TargetComponent == nullptr ||
			TargetComponent.Owner == nullptr)
			return;

		auto OutermostActor = DarkPortal::GetOutermostActor(TargetComponent.Owner);
		auto ResponseComponent = DarkPortal::GetFirstHierarchyResponseComponent(TargetComponent.Owner);
		if (OutermostActor == nullptr)
			return;

		bool bWasInitialGrab = Grabs.Num() == 0;

		int GrabIndex = GetActorGrabIndex(OutermostActor);
		if (GrabIndex >= 0)
		{
			auto& Grab = Grabs[GrabIndex];
			if (Grab.TargetComponents.Contains(TargetComponent))
				return;

			Grab.TargetComponents.Add(TargetComponent);

			// We have to trigger grab event for the component
			//  if the response event has already fired
			if (Grab.bHasTriggeredResponse)
			{
				DarkPortal::TriggerHierarchyGrab(this, TargetComponent);
			}
		}
		else
		{
			FDarkPortalUserGrab Grab;
			Grab.Actor = OutermostActor;
			Grab.Timestamp = Time::GameTimeSeconds;
			Grab.ResponseComponent = ResponseComponent;
			Grab.TargetComponents.Add(TargetComponent);
			//Debug::DrawDebugSphere(TargetComponent.GetWorldLocation(), 200, 32, FLinearColor::Red);
			Grabs.Add(Grab);
		}
		TargetComponent.OnGrabbed();	

		if(bWasInitialGrab)
			UDarkPortalEventHandler::Trigger_StartGrabbingObject(this, FDarkPortalGrabEventData(TargetComponent));
	}

	UFUNCTION(CrumbFunction)
	void CrumbRelease(UDarkPortalTargetComponent TargetComponent)
	{
		Release(TargetComponent);
	}

	void Release(UDarkPortalTargetComponent TargetComponent)
	{
		if (TargetComponent == nullptr)
			return;
		if (TargetComponent.Owner == nullptr)
			return;

		for (int i = Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = Grabs[i];

			if (Grab.Actor == TargetComponent.Owner)
			{
				if (Grab.TargetComponents.Remove(TargetComponent) > 0)
				{
					if (Grab.bHasTriggeredResponse)
						DarkPortal::TriggerHierarchyRelease(this, TargetComponent);
				}

				if (Grab.TargetComponents.Num() == 0)
					Grabs.RemoveAt(i);

				break;
			}
		}

		if(Grabs.Num() == 0)
			UDarkPortalEventHandler::Trigger_StopGrabbingObject(this);
	}

	void PushAndReleaseAll()
	{
		bool bHadActiveGrab = HasActiveGrab();

		FVector AccumulatedImpulse = FVector::ZeroVector;
		for (const auto& Grab : Grabs)
		{
			if (Grab.TargetComponents.Num() == 0 || !Grab.bHasTriggeredResponse)
				continue;

			for (auto TargetComponent : Grab.TargetComponents)
			{
				if (Grab.ResponseComponent != nullptr)
				{
					auto AffectedComponent = DarkPortal::GetParentForceAnchor(TargetComponent);
					FVector PortalToAffected = (Grab.ResponseComponent.GetOriginLocationForPortal(this) - AffectedComponent.WorldLocation);
					float AffectedDistance = PortalToAffected.Size();
	
					float PushFraction = Math::Pow(1.0 - Math::Clamp(AffectedDistance / DarkPortal::Grab::PushRadius, 0.0, 1.0), DarkPortal::Grab::PushExponent);
					float DistanceFraction = 1.0 - Math::Clamp(AffectedDistance / (TargetComponent.MaximumDistance), 0.0, 1.0);

					// Avoid pushing behind portal
					FVector Direction = PortalToAffected.GetSafeNormal();
					if (ActorForwardVector.DotProduct(Direction) < 0.0)
						Direction *= -1.0;

					// Shift push direction towards portal forward vector the closer the target
					//  gets to the portal; limits things flying in every direction when they're close
					Direction = Math::Lerp(Direction, ActorForwardVector, DistanceFraction);

					// Temp fix to prevent any pushing - this should be cleaned up / Robert
					FVector Impulse = Direction * 0.0 * PushFraction;
//					FVector Impulse = Direction * Grab.ResponseComponent.PushImpulse * PushFraction;

					DarkPortal::TriggerHierarchyPush(this,
						TargetComponent,
						AffectedComponent.WorldLocation,
						Impulse);

					DarkPortal::TriggerHierarchyRelease(this, TargetComponent);

					AccumulatedImpulse += Impulse;
				}
			}
		}
		Grabs.Empty();

		if (bHadActiveGrab)
		{
			if (AttachResponse != nullptr)
			{
				FVector ForceDirection = AccumulatedImpulse.GetSafeNormal(KINDA_SMALL_NUMBER, ActorForwardVector);

				// Temp fix to prevent any pushing - this should be cleaned up / Robert
				FVector Impulse = -ForceDirection * 0.0;
//				FVector Impulse = -ForceDirection * AttachResponse.PushImpulse;

				DarkPortal::TriggerHierarchyPush(this,
					RootComponent.AttachParent,
					ActorLocation,
					Impulse);
			}
			
			UDarkPortalEventHandler::Trigger_Pushed(this);
		}

		if(State != EDarkPortalState::Recall)
			UDarkPortalEventHandler::Trigger_StopGrabbingObject(this);			
	}

	void AttachPortal(FTransform AttachTransform, USceneComponent SceneComponent, FName SocketName = NAME_None)
	{
		if (SceneComponent == nullptr)
		{
			devError(f"Attempting to attach to invalid scene component.");
			return;
		}

		ActorTransform = AttachTransform;

		if (RootComponent.AttachParent != nullptr)
			DetachPortal();

		DarkPortal::TriggerHierarchyAttach(this, SceneComponent);
		AttachResponse = DarkPortal::GetFirstHierarchyResponseComponent(SceneComponent.Owner);
		AttachToComponent(SceneComponent, SocketName, EAttachmentRule::KeepWorld);
	}

	void DetachPortal()
	{
		if (RootComponent.AttachParent == nullptr)
			return;

		DarkPortal::TriggerHierarchyDetach(this, RootComponent.AttachParent);
		AttachResponse = nullptr;
		DetachRootComponentFromParent();
	}

	UFUNCTION(BlueprintCallable)
	void RequestDespawn()
	{
		bDespawnRequested = true;
	}
	
	UFUNCTION(BlueprintCallable)
	void RequestRelease()
	{
		ReleaseRequestTimestamp = Time::GameTimeSeconds;
	}

	// Composite check for whether we should grab a component.
	bool ShouldGrab(UDarkPortalTargetComponent TargetComponent, float ExtendedRange) const
	{
		// Check if we want to ignore conditions for grabbing
		if (bForcedGrabs && TargetComponent != nullptr && IsInRange(TargetComponent, ExtendedRange))
			return true;

		if (TargetComponent == nullptr)
			return false;
		if (TargetComponent.IsDisabledForPlayer(Player))
			return false;		
		if (TargetComponent.IsDisabled())
			return false;
		if (!IsInRange(TargetComponent, ExtendedRange))
			return false;
		if (!IsOmnidirectional())
		{
			if (!HasFieldOfView(TargetComponent))
				return false;
		}
		if (!IsWithinCustomAngle(TargetComponent))
			return false;
		// if (IsAttachedToHierarchy(TargetComponent))
		// 	return false;
		auto ResponseComp = UDarkPortalResponseComponent::Get(TargetComponent.Owner);
		if (ResponseComp == nullptr || !ResponseComp.bAllowMultiComponentGrab)
		{
			if (IsGrabbingHierarchy(TargetComponent))
				return false;
		}
		else
		{
			if (IsGrabbingComponent(TargetComponent))
				return false;
		}
		if (!HasLineOfSight(TargetComponent))
			return false;

		return true;
	}

	// Composite check for whether we should release a component.
	bool ShouldRelease(UDarkPortalTargetComponent TargetComponent) const
	{
		// Check if we want to ignore conditions for grabbing
		if (bForcedGrabs && TargetComponent != nullptr)
			return false;

		if (TargetComponent == nullptr)
			return true;
		if (TargetComponent.IsDisabledForPlayer(Player))
			return true;
		// if (!IsInRange(TargetComponent, MaxRange))
		// 	return true;
		// if (!IsOmnidirectional())
		// {
		// 	if (!HasFieldOfView(TargetComponent))
		// 		return true;
		// }
		
		if (Time::GetGameTimeSince(TargetComponent.LastGrabbedTime) < TargetComponent.MinGrabTime)
			return false; // Always disregard angles and LOS for a short while to avoid flickering grab/release

		if (TargetComponent.bAutoReleaseLimited)
		{
			if (!IsWithinCustomAngle(TargetComponent))
				return true;
		}
		// if (IsAttachedToHierarchy(TargetComponent))
		// 	return true;
		// if (IsGrabbingHierarchy(TargetComponent))
		// 	return true;
		if (!TargetComponent.bIgnoreLOSWhenGrabbed && !HasLineOfSight(TargetComponent))
			return true;

		return false;
	}

	bool IsInRange(UDarkPortalTargetComponent TargetComponent, float ExtendedRange) const
	{
		const float GrabRangeSqr = Math::Square(TargetComponent.MaximumDistance + ExtendedRange);
		const float TargetDistanceSqr = ActorLocation.DistSquared(TargetComponent.WorldLocation);

		return (TargetDistanceSqr < GrabRangeSqr);
	}

	bool HasFieldOfView(UDarkPortalTargetComponent TargetComponent) const
	{
		if (TargetComponent == nullptr)
			return false;

		const FVector ToTarget = (TargetComponent.WorldLocation - ActorLocation);
		const FVector TargetDirection = ToTarget.GetSafeNormal();
		const float TargetAngle = Math::RadiansToDegrees(
			TargetDirection.AngularDistanceForNormals(ActorForwardVector)
		);

		if (TargetAngle > DarkPortal::Grab::MaxAngle)
			return false;

		return true;
	}

	bool IsWithinCustomAngle(UDarkPortalTargetComponent TargetComponent) const
	{
		if (TargetComponent == nullptr)
			return false;

		if (TargetComponent.bLimitAngle)
		{
			const FVector ToPortal = (ActorLocation - TargetComponent.WorldLocation);
			const FVector PortalDirection = ToPortal.GetSafeNormal();
			const float Angle = Math::RadiansToDegrees(
				PortalDirection.AngularDistanceForNormals(TargetComponent.UpVector)
			);

			if (Angle > TargetComponent.LimitedAngle)
				return false;
		}
		
		return true;
	}

	bool HasLineOfSight(UDarkPortalTargetComponent TargetComponent) const
	{
		if (TargetComponent == nullptr)
			return false;

		const FVector TraceStart = OriginLocation;
		const FVector TraceEnd = TargetComponent.WorldLocation;
		if (TraceStart.IsWithinDist(TraceEnd, 1.0))
			return true; // We're not allowed to do a zero length trace

		auto Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);

		// TODO: Actors occasionally move behind the portal into the attached object
		//  should probably be removed when there's some kind of collision
		if (AttachParentActor != nullptr)
			Trace.IgnoreActor(AttachParentActor);

		Trace.IgnoreActors(Game::Players);

		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);
		return (!HitResult.bBlockingHit || HitResult.Actor == TargetComponent.Owner);
	}

	// Check if the target component is a part of our attached actor's hierarchy.
	bool IsAttachedToHierarchy(UDarkPortalTargetComponent TargetComponent) const
	{
		auto TargetOutermostActor = DarkPortal::GetOutermostActor(TargetComponent.Owner);
		auto AttachOutermostActor = DarkPortal::GetOutermostActor(AttachParentActor);

		return (AttachOutermostActor != nullptr && TargetOutermostActor == AttachOutermostActor);
	}

	// Check if we're already grabbing something in the target component's hierarchy.
	bool IsGrabbingHierarchy(UDarkPortalTargetComponent TargetComponent) const
	{
		auto OutermostActor = DarkPortal::GetOutermostActor(TargetComponent.Owner);
		return (GetActorGrabIndex(OutermostActor) >= 0);
	}
	
	// Check if we're already grabbing the target component.
	bool IsGrabbingComponent(UDarkPortalTargetComponent TargetComponent) const
	{
		auto OutermostActor = DarkPortal::GetOutermostActor(TargetComponent.Owner);
		
		int GrabIndex = GetActorGrabIndex(OutermostActor);
		if (GrabIndex >= 0)
		{
			const auto& Grab = Grabs[GrabIndex];
			return Grab.TargetComponents.Contains(TargetComponent);
		}

		return false;
	}

	// temp while we work on optimizing the Arms
	bool bDebugNextGen = true;

	UFUNCTION(BlueprintCallable, Category = "Portal")
	void SpawnArms()
	{
		if (ArmEffect == nullptr)
			return;

		for (int i = SpawnedArms.Num(); i < DarkPortal::Grab::MaxGrabs; ++i)
		{
			FVector2D Offset2D = Math::RandPointInCircle(DarkPortal::Arms::OffsetRadius);

			auto Arm = UDarkPortalArmComponent::Create(this);

			// index 0 is master comp that will simulate all arms. 
			// The other arm comps will only be data comps for now, 
			// until we get the chance to rewrite it again and migrate 
			// the data from components to structs instead.
			if(bDebugNextGen)
			{
				if(i == 0)
				{
					Arm.Asset = ArmEffect;
				}

				// This should ideally be replaced with and offset applied within niagara. TEMP
				// Arm.RelativeLocation = FVector::ZeroVector;
				if (!IsOmnidirectional())
				{
					Arm.RelativeLocation = FVector(0.0, Offset2D.X, Offset2D.Y);
				}
				else
				{
					Arm.RelativeRotation = FRotator::MakeFromX(Math::GetRandomPointOnSphere());
				}
			}
			else
			{
				Arm.Asset = ArmEffect;
				
				if (!IsOmnidirectional())
				{
					Arm.RelativeLocation = FVector(0.0, Offset2D.X, Offset2D.Y);
				}
				else
				{
					Arm.RelativeRotation = FRotator::MakeFromX(Math::GetRandomPointOnSphere());
				}
			}

			Arm.Initialize(i);
			SpawnedArms.Add(Arm);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Portal")
	void DestroyArms()
	{
		for (int i = SpawnedArms.Num() - 1; i >= 0; --i)
			SpawnedArms[i].DestroyComponent(this);

		SpawnedArms.Empty();
	}

	UFUNCTION(BlueprintPure, Category = "Portal")
	FVector GetOriginLocation() const property
	{
		return (ActorLocation + ActorForwardVector * DarkPortal::Grab::OriginOffset);
	}

	UFUNCTION(BlueprintPure)
	bool IsGrabbingAny() const
	{
		for (const auto& Grab : Grabs)
		{
			if (Grab.TargetComponents.Num() != 0)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	int GetNumGrabbedComponents() const
	{
		int NumComponents = 0;
		for (const auto& Grab : Grabs)
			NumComponents += Grab.TargetComponents.Num();

		return NumComponents;
	}

	UFUNCTION(BlueprintPure)
	int GetNumActiveGrabbedComponents() const
	{
		int NumComponents = 0;
		for (const auto& Grab : Grabs)
		{
			if (Grab.bHasTriggeredResponse)
				NumComponents += Grab.TargetComponents.Num();
		}

		return NumComponents;
	}

	UFUNCTION(BlueprintPure)
	bool IsOmnidirectional() const
	{
		if (RootComponent.AttachParent == nullptr)
			return false;
		if (AttachResponse == nullptr)
			return false;
		if (!AttachResponse.bOmnidirectional)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool IsAttachValid() const
	{
		if (RootComponent.AttachParent == nullptr)
		 	return false;
		if (RootComponent.AttachParent.IsBeingDestroyed())
			return false;

		// If it's BSP, don't do actor checks
		if (AttachParentActor != nullptr)
		{
			if (AttachParentActor.IsActorBeingDestroyed())
				return false;
			if (AttachParentActor.IsActorDisabled())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasActiveGrab() const
	{
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].bHasTriggeredResponse && Grabs[i].TargetComponents.Num() != 0)
				return true;
		}

		return false;
	}

	int GetActorGrabIndex(AActor Actor) const
	{
		if (Actor == nullptr)
			return -1;

		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].Actor == Actor)
				return i;
		}

		return -1;
	}

	UFUNCTION(BlueprintPure)
	bool IsAbsorbed() const
	{
		return State == EDarkPortalState::Absorb;
	}

	UFUNCTION(BlueprintPure)
	bool IsLaunching() const
	{
		return State == EDarkPortalState::Launch;
	}

	UFUNCTION(BlueprintPure)
	bool IsSettled() const
	{
		return State == EDarkPortalState::Settle;
	}

	UFUNCTION(BlueprintPure)
	bool IsRecalling() const
	{
		return State == EDarkPortalState::Recall;
	}

	UFUNCTION(BlueprintPure)
	bool IsGrabbingActive() const
	{
		return bIsGrabActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsMegaPortal() const
	{
		return bIsMegaPortal;
	}

	FDarkPortalTargetData GetTargetDataFromTrace(FVector Origin, FVector Destination)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);

		auto HitResult = Trace.QueryTraceSingle(Origin, Destination);
	
		if (HitResult.bBlockingHit)
		{
			if (HitResult.Component != nullptr &&
				HitResult.Component.HasTag(n"DarkPortalPlaceable"))
			{
				return FDarkPortalTargetData(
					HitResult.Component,
					HitResult.BoneName,
					HitResult.ImpactPoint,
					HitResult.ImpactNormal,
					false
				);
			}
			else
			{
				return FDarkPortalTargetData(
					nullptr,
					NAME_None,
					HitResult.ImpactPoint,
					HitResult.ImpactNormal,
					true
				);
			}
		}
		else
		{
			return FDarkPortalTargetData(
				nullptr,
				NAME_None,
				HitResult.TraceEnd,
				Player.MovementWorldUp,
				false
			);
		}
	}
}
