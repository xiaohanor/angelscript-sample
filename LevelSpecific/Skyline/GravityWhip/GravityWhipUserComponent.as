struct FGravityWhipUserGrab
{
	AActor Actor;
	UGravityWhipResponseComponent ResponseComponent;
	TArray<UGravityWhipTargetComponent> TargetComponents;
	bool bHasTriggeredResponse = false;
	bool bForcedGrab = false;
	float Timestamp = 0.0;

	FVector PrevGrabLocation;
	FVector GrabVelocity;
}

struct FGravityWhipTargetData
{
	FName CategoryName = NAME_None;
	EGravityWhipGrabMode GrabMode = EGravityWhipGrabMode::Drag;
	bool bAllowMultiGrab = true;
	TArray<UGravityWhipTargetComponent> TargetComponents;
}

struct FGravityWhipGrabPoint
{
	UGravityWhipTargetComponent TargetComponent = nullptr;
	UPrimitiveComponent PrimitiveComponent = nullptr;
	FVector RelativeLocation = FVector::ZeroVector;

	FVector GetWorldLocation() const property
	{
		if (TargetComponent == nullptr)
			return RelativeLocation;

		return TargetComponent
			.WorldTransform
			.TransformPositionNoScale(RelativeLocation);
	}
}

struct FGravityWhipActiveGloryKill
{
	bool bMoveEnforcerToPoint = false;
	FVector EnforcerTargetPoint;
	FGravityWhipGloryKillSequence Sequence;
}

UCLASS(Abstract)
class UGravityWhipUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	TSubclassOf<AGravityWhipActor> WhipClass;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	TSubclassOf<UGravityWhipCrosshairWidget> CrosshairWidget;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	TSubclassOf<UTargetableWidget> TargetWidgetClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	TSubclassOf<UGravityWhipGrabbableTargetWidget> GrabbableTargetWidget;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	UHazeCameraSpringArmSettingsDataAsset DragCameraSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	UHazeCameraSpringArmSettingsDataAsset SlingCameraSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	UHazeCameraSpringArmSettingsDataAsset GloryKillCameraSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
    UOutlineDataAsset TargetOutline;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
    UForceFeedbackEffect HitForceFeedback;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
    UForceFeedbackEffect SlingThrowForceFeedback;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Whip")
	FGravityWhipAnimationData AnimationData;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Whip")
	AGravityWhipActor Whip;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Whip")
	FVector GrabCenterLocation = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip|Gravity Blade")
	TSubclassOf<UGravityBladeCombatZoeTargetableWidget> GravityBladeTargetWidget;

	FGravityWhipTargetData TargetData;
	TArray<FGravityWhipUserGrab> Grabs;
	float GrabTimestamp = -1.0;
	float ReleaseTimestamp = 0.0;
	bool bReleaseStrafeImmediately = false;

	TOptional<FGravityWhipActiveGloryKill> ActiveGloryKill;
	int LastGloryKillIndex = -1;
	bool bGloryKillMovementLocked = false;

	TArray<FGravityWhipGrabPoint> GrabPoints;
	bool bIsAirGrabbing;
	bool bWhipGrabHadTarget;
	bool bIsSlingThrowing;
	FVector WantedDragDirection;

	bool bInsideHitWindow = false;
	EAnimHitPitch HitPitch;
	EHazeCardinalDirection HitDirection;
	float HitWindowPushbackMultiplier;
	float HitWindowExtraPushback;

	bool bTorHammerAttackStart = false;
	bool bTorHammerAttackEnd = false;

	bool bIsHolstered = true;
	float BufferedPressTime = -1.0;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);

		for (int i = 0; i < GravityWhip::Grab::MaxNumGrabs; ++i)
			GrabPoints.Add(FGravityWhipGrabPoint());

		if (WhipClass != nullptr)
		{
			FTransform SocketTransform = Player.Mesh.GetSocketTransform(GravityWhip::Common::IdleAttachSocket);

			Whip = SpawnActor(WhipClass, SocketTransform.Location, SocketTransform.Rotator(), bDeferredSpawn = true);
			Whip.MakeNetworked(this, n"GravityWhipActor");
			FinishSpawningActor(Whip);
			Whip.AttachToComponent(Player.Mesh, GravityWhip::Common::IdleAttachSocket, EAttachmentRule::SnapToTarget);
			Whip.ActorRelativeTransform = GravityWhip::Common::IdleAttachTransform;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (Whip != nullptr)
        {
            Whip.DetachRootComponentFromParent();
            Whip.DestroyActor();
            Whip = nullptr;
        }
	}

	bool IsWhipSpawned() const
	{
		if(Whip == nullptr)
			return false;

		return true;
	}

	bool IsWhipPressBuffered() const
	{
		if (BufferedPressTime < 0)
			return false;

		float TimeSinceRelease = Time::GetGameTimeSince(ReleaseTimestamp);
		if (TimeSinceRelease > GravityWhip::Grab::ReleaseDuration + 0.1)
			return false;
		if (Time::GetGameTimeSince(BufferedPressTime) > 2.0)
			return false;

		return true;
	}

	void BufferWhipPress()
	{
		BufferedPressTime = Time::GameTimeSeconds;
	}

	void ConsumeBufferedWhipPress()
	{
		BufferedPressTime = -1.0;
	}

	UFUNCTION() // Temp for blueprint madness
	void Grab(const TArray<UGravityWhipTargetComponent>& TargetComponents)
	{
		for (int i = 0; i < TargetComponents.Num(); ++i)
		{
			auto TargetComponent = TargetComponents[i];
			if (!IsValid(TargetComponent))
				continue;

			auto ResponseComponent = UGravityWhipResponseComponent::Get(TargetComponent.Owner);

			// TODO: More clean up once legacy can be removed
			if (!GravityWhip::Grab::bLegacyTargetExclusion)
			{
				if (ResponseComponent.CategoryName != TargetData.CategoryName ||
					ResponseComponent.GrabMode != TargetData.GrabMode)
				{
					// Either filtering failed or someone is trying to be sneaky
					devCheck(false, f"Attempting to grab a targetable with mismatched response component settings.");
					continue;
				}
			}

			int GrabIndex = GetActorGrabIndex(TargetComponent.Owner);
			if (GrabIndex >= 0)
			{
				auto& Grab = Grabs[GrabIndex];
				if (Grab.TargetComponents.Contains(TargetComponent))
					continue;

				Grab.TargetComponents.Add(TargetComponent);

				if (ResponseComponent != nullptr && Grab.bHasTriggeredResponse)
				{
					FGravityWhipGrabData GrabData;
					GrabData.TargetComponent = TargetComponent;
					GrabData.HighlightPrimitive = GetPrimitiveParent(TargetComponent);
					GrabData.GrabMode = Grab.ResponseComponent.GrabMode;
					UGravityWhipEventHandler::Trigger_TargetGrabbed(Player, GrabData);

					ResponseComponent.Grab(this, TargetComponent, TargetComponents);
				}
			}
			else
			{
				FGravityWhipUserGrab Grab;
				Grab.Actor = TargetComponent.Owner;
				Grab.ResponseComponent = ResponseComponent;
				Grab.Timestamp = Time::GameTimeSeconds;
				Grab.PrevGrabLocation = TargetComponent.WorldLocation;
				Grab.TargetComponents.Add(TargetComponent);

				Grabs.Add(Grab);
			}

			FGravityWhipGrabData GrabData;
			GrabData.TargetComponent = TargetComponent;
			GrabData.GrabMode = ResponseComponent.GrabMode;
			GrabData.AudioData = TargetComponent.AudioData;

			UGravityWhipEventHandler::Trigger_TargetStartGrab(Player, GrabData);

			if (ResponseComponent != nullptr)
				ResponseComponent.OnStartGrabSequence.Broadcast();
		}
	}

	void Release(AActor Actor)
	{
		if (Actor == nullptr)
			return;

		int GrabIndex = GetActorGrabIndex(Actor);
		if (GrabIndex >= 0)
		{
			auto& Grab = Grabs[GrabIndex];

			auto ResponseComponent = UGravityWhipResponseComponent::Get(Actor);
			for (auto TargetComponent : Grab.TargetComponents)
			{
				if (ResponseComponent != nullptr && Grab.bHasTriggeredResponse)
					ResponseComponent.Release(this, TargetComponent, FVector::ZeroVector);

				FGravityWhipReleaseData ReleaseData;
				ReleaseData.TargetComponent = TargetComponent;
				ReleaseData.HighlightPrimitive = GetPrimitiveParent(TargetComponent);
				ReleaseData.Impulse = FVector::ZeroVector;
				ReleaseData.AudioData = TargetComponent.AudioData;

				UGravityWhipEventHandler::Trigger_TargetReleased(Player, ReleaseData);
			}

			if (ResponseComponent != nullptr)
				ResponseComponent.OnEndGrabSequence.Broadcast();

			Grabs.RemoveAt(GrabIndex);
		}
	}

	void Release(UGravityWhipTargetComponent TargetComponent)
	{
		if (TargetComponent == nullptr)
			return;

		int GrabIndex = GetActorGrabIndex(TargetComponent.Owner);
		if (GrabIndex >= 0)
		{
			auto& Grab = Grabs[GrabIndex];
			if (!Grab.TargetComponents.Contains(TargetComponent))
				return;

			Grab.TargetComponents.Remove(TargetComponent);

			if (Grab.TargetComponents.Num() == 0)
			{
				auto ResponseComponent = UGravityWhipResponseComponent::Get(TargetComponent.Owner);
				if (ResponseComponent != nullptr && Grab.bHasTriggeredResponse)
					ResponseComponent.Release(this, TargetComponent, FVector::ZeroVector);

				FGravityWhipReleaseData ReleaseData;
				ReleaseData.TargetComponent = TargetComponent;
				ReleaseData.HighlightPrimitive = GetPrimitiveParent(TargetComponent);
				ReleaseData.Impulse = FVector::ZeroVector;
				ReleaseData.AudioData = TargetComponent.AudioData;

				UGravityWhipEventHandler::Trigger_TargetReleased(Player, ReleaseData);

				if (ResponseComponent != nullptr)
					ResponseComponent.OnEndGrabSequence.Broadcast();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbRelease(UGravityWhipTargetComponent TargetComponent)
	{
		Release(TargetComponent);
	}

	void ReleaseAll()
	{
		for (auto& Grab : Grabs)
		{
			auto ResponseComponent = UGravityWhipResponseComponent::Get(Grab.Actor);
			for (auto TargetComponent : Grab.TargetComponents)
			{
				if (ResponseComponent != nullptr && Grab.bHasTriggeredResponse)
					ResponseComponent.Release(this, TargetComponent, FVector::ZeroVector);

				FGravityWhipReleaseData ReleaseData;
				ReleaseData.TargetComponent = TargetComponent;
				ReleaseData.Impulse = FVector::ZeroVector;	
				ReleaseData.AudioData = TargetComponent.AudioData;

				UGravityWhipEventHandler::Trigger_TargetReleased(Player, ReleaseData);
			}

			if (ResponseComponent != nullptr)
				ResponseComponent.OnEndGrabSequence.Broadcast();
		}

		Grabs.Empty();
	}

	FVector CalculateThrowImpulse(UGravityWhipTargetComponent TargetComponent,
		float OffsetDistance,
		float ImpulseMultiplier)
	{
		auto AimingRay = AimComp.GetPlayerAimingRay();
		FVector AimOrigin = Math::ClosestPointOnInfiniteLine(
			AimingRay.Origin,
			AimingRay.Origin + (AimingRay.Direction * TargetComponent.MaximumDistance),
			Player.ActorCenterLocation
		);
		
		FVector TargetDirection = (TargetComponent.WorldLocation - AimOrigin).GetSafeNormal();
		float TargetAngle = Math::RadiansToDegrees(
			TargetDirection.AngularDistanceForNormals(AimingRay.Direction)
		);

		float DefaultImpulse = GravityWhip::Grab::ThrowImpulse;
		float AngularAlpha = Math::Saturate(TargetAngle / GravityWhip::Grab::MaxThrowAngle);
		FVector ThrowDirection = (GetDragOrigin(OffsetDistance) - TargetComponent.WorldLocation).GetSafeNormal();

		return (ThrowDirection * DefaultImpulse * ImpulseMultiplier * AngularAlpha);
	}

	FHitResult QueryWithRay(FVector Origin, FVector Direction, float TraceRange, FVector& AimLocation) const
	{
		if (Origin.ContainsNaN() || Direction.IsNearlyZero())
			return FHitResult();

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].Actor != nullptr)
				Trace.IgnoreActor(Grabs[i].Actor);
		}

		auto HitResult = Trace.QueryTraceSingle(Origin + Direction * 100.0, Origin + Direction * TraceRange);

		AimLocation = HitResult.TraceEnd;
		if (HitResult.bBlockingHit)
			AimLocation = HitResult.ImpactPoint;

		return HitResult;
	}

	UFUNCTION(BlueprintPure)
	FVector GetDragOrigin(float OffsetDistance) const
	{
		auto AimRay = GetAimingRay();
		return AimRay.Origin + (AimRay.Direction * OffsetDistance);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetSlingOrigin() const
	{
		return Player.Mesh.GetSocketTransform(n"Align");
	}

	UFUNCTION(BlueprintPure)
	bool IsTargetingAny() const
	{
		return TargetData.TargetComponents.Num() != 0;
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
	bool HasGrabbedActor(AActor Actor) const
	{
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].Actor == Actor)
				return true;
		}

		return false;
	}

	bool HasGrabbedSlingableWithAutoAimCategory(FName Category) const
	{
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].ResponseComponent == nullptr)
				continue;
			if (Grabs[i].ResponseComponent.GrabMode != EGravityWhipGrabMode::Sling)
				continue;
			if (!Grabs[i].ResponseComponent.SlingAutoAimCategories.Contains(Category))
				continue;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool HasGrabPoints() const
	{
		for (const auto& GrabPoint : GrabPoints)
		{
			if (GrabPoint.TargetComponent != nullptr)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool HasActiveGrab() const
	{
		for (const auto& Grab : Grabs)
		{
			if (Grab.TargetComponents.Num() != 0 && (Grab.bHasTriggeredResponse || Grab.bForcedGrab))
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
	FGravityWhipUserGrab GetPrimaryGrab() const
	{
		for (const auto& Grab : Grabs)
		{
			if (Grab.TargetComponents.Num() != 0)
				return Grab;
		}

		return FGravityWhipUserGrab();
	}

	UFUNCTION(BlueprintPure)
	UGravityWhipTargetComponent GetPrimaryTarget() const
	{
		for (const auto& Grab : Grabs)
		{
			if (Grab.TargetComponents.Num() != 0)
				return Grab.TargetComponents[0];
		}

		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	FName GetPrimaryCategoryName() const
	{
		return TargetData.CategoryName;
	}

	UFUNCTION(BlueprintPure)
	EGravityWhipGrabMode GetPrimaryGrabMode() const
	{
		return TargetData.GrabMode;
	}

	FAimingRay GetAimingRay(bool bPlaceOriginAtPlayerDepth = true) const
	{
		auto Ray = AimComp.GetPlayerAimingRay();
		const float MinDistance = (Ray.Origin - Player.ActorCenterLocation).Size() * 2.0;
		if (bPlaceOriginAtPlayerDepth)
		{
			Ray.Origin = Math::ClosestPointOnInfiniteLine(
				Ray.Origin,
				Ray.Origin + (Ray.Direction * MinDistance),
				Player.ActorCenterLocation
			);
		}
		return Ray;
	}

	float GetConstrainedAngle(const FVector& A,
		const FVector& B,
		const FVector& UpVector) const
	{
		FVector ConstrainedA = A.ConstrainToPlane(UpVector).GetSafeNormal();
		FVector ConstrainedB = B.ConstrainToPlane(UpVector).GetSafeNormal();

		float ConstrainedAngle = Math::RadiansToDegrees(
			ConstrainedA.AngularDistanceForNormals(ConstrainedB)
		);
		FVector ACrossB = ConstrainedA.CrossProduct(ConstrainedB);

		if (ACrossB.DotProduct(UpVector) > 0.0)
			ConstrainedAngle *= -1.0;

		return ConstrainedAngle;
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

	void GetGrabbedComponents(TArray<UGravityWhipTargetComponent>&out GrabbedComponents) const
	{
		for (const auto& Grab : Grabs)
			GrabbedComponents.Append(Grab.TargetComponents);
	}

	void GetTargetedComponents(TArray<UGravityWhipTargetComponent>&out TargetedComponents) const
	{
		TargetedComponents.Append(TargetData.TargetComponents);
	}

	// temp for basic highlight vfx setup
	UPrimitiveComponent GetPrimitiveParent(USceneComponent Child) const
	{
		USceneComponent Parent = Child.AttachParent;
		UPrimitiveComponent Primitive = nullptr;
		while (Parent != nullptr && Primitive == nullptr)
		{
			Primitive = Cast<UPrimitiveComponent>(Parent);
			Parent = Parent.AttachParent;
		}

		return nullptr;
	}
}