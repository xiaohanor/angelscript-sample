event void FDarkPortalAttachSignature(ADarkPortalActor Portal, USceneComponent AttachComponent);
event void FDarkPortalGrabSignature(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent);
event void FDarkPortalReleaseSignature(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent);
event void FDarkPortalPushSignature(ADarkPortalActor Portal, USceneComponent PushedComponent, FVector WorldLocation, FVector Impulse);
event void FDarkPortalExplosionSignature(ADarkPortalActor Portal, FVector Direction);

struct FDarkPortalResponseAttach
{
	ADarkPortalActor Portal = nullptr;
	USceneComponent AttachComponent = nullptr;
	FVector PendingForce = FVector::ZeroVector;
	FVector PreviousForce = FVector::ZeroVector;

	FVector ConsumeForce()
	{
		PreviousForce = PendingForce;
		PendingForce = FVector::ZeroVector;
		return PreviousForce;
	}
}

struct FDarkPortalResponseGrab
{
	ADarkPortalActor Portal = nullptr;
	UDarkPortalTargetComponent TargetComponent = nullptr;
	FVector PendingForce = FVector::ZeroVector;
	FVector PreviousForce = FVector::ZeroVector;

	FVector GrabTargetLocation;
	FVector GrabTargetForward;

	FVector ConsumeForce()
	{
		PreviousForce = PendingForce;
		PendingForce = FVector::ZeroVector;
		return PreviousForce;
	}
}

class UDarkPortalResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalAttachSignature OnAttached;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalAttachSignature OnDetached;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalGrabSignature OnGrabbed;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalGrabSignature OnInitialGrab;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalReleaseSignature OnReleased;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalReleaseSignature OnLastRelease;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalPushSignature OnPushed;
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FDarkPortalExplosionSignature OnExploded;

	// Used by VO
	UPROPERTY(Category = "Response")
	FDarkPortalAttachSignature OnAttachedInBounds;
	UPROPERTY(Category = "Response")
	FDarkPortalAttachSignature OnDetachedInBounds;

	// Whether we want the portal to be omni-directional (360 degree grab) while attached to this object.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	bool bOmnidirectional = false;

	/**
	 * Whether we want to disable attaching the bird to the portal while it's attached to this object.
	 * NOTE: Also disables the portal/lightbird explosion combo.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	bool bDisableBirdAttach = false;

	// Whether we're allowed to grab multiple components of this actor at the same time.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	bool bAllowMultiComponentGrab = false;

	// Maximum pull force applied every frame while grabbed.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	float PullForce = DarkPortal::Grab::DefaultPullForce;

	// Maximum impulse applied when pushed.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	float PushImpulse = DarkPortal::Grab::DefaultPushImpulse;

	// Additional offset applied to the dark portal's pull origin
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	float PortalOriginOffset = 0.0;

	UPROPERTY(Instanced, EditInstanceOnly, Category = "Response")
	private FBoxSphereBounds PortalSettleResponseBounds;
	TOptional<FBoxSphereBounds> SettleResponseBounds;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FSoundDefReference SoundDefAsset;

	TArray<FDarkPortalResponseAttach> Attaches;
	TArray<FDarkPortalResponseGrab> Grabs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SoundDefAsset.SoundDef.IsValid())
			SoundDefAsset.SpawnSoundDefAttached(Owner);

		if(!PortalSettleResponseBounds.BoxExtent.IsZero())
		{
			FBoxSphereBounds Bounds;	
			Bounds = PortalSettleResponseBounds;
			Bounds.Origin = Owner.ActorLocation + PortalSettleResponseBounds.Origin;
			SettleResponseBounds.Set(Bounds);
		}
	}

	void Attach(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		FDarkPortalResponseAttach Attach;
		Attach.Portal = Portal;
		Attach.AttachComponent = AttachComponent;
		Attaches.Add(Attach);

		OnAttached.Broadcast(Portal, AttachComponent);

		if(SettleResponseBounds.IsSet())
		{
			if(Math::IsPointInBox(Portal.TargetData.WorldLocation, SettleResponseBounds.Value.Origin, SettleResponseBounds.Value.BoxExtent))
				OnAttachedInBounds.Broadcast(Portal, AttachComponent);
		}
	}

	void Detach(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		for (int i = Attaches.Num() - 1; i >= 0; --i)
		{
			if (Attaches[i].Portal == Portal &&
				Attaches[i].AttachComponent == AttachComponent)
			{
				Attaches.RemoveAt(i);
				break;
			}
		}

		OnDetached.Broadcast(Portal, AttachComponent);

		if(SettleResponseBounds.IsSet())
		{
			if(Math::IsPointInBox(Portal.TargetData.WorldLocation, SettleResponseBounds.Value.Origin, SettleResponseBounds.Value.BoxExtent))
				OnDetachedInBounds.Broadcast(Portal, AttachComponent);
		}
	}

	void Grab(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		const bool bWasGrabbed = Grabs.Num() > 0;

		FDarkPortalResponseGrab Grab;
		Grab.Portal = Portal;
		Grab.TargetComponent = TargetComponent;
		Grabs.Add(Grab);

		if (DevTogglesDarkPortal::DebugDraw.IsEnabled())
			Debug::DrawDebugSphere(Grab.TargetComponent.WorldLocation);

		OnGrabbed.Broadcast(Portal, TargetComponent);

		if(!bWasGrabbed)
		{
			OnInitialGrab.Broadcast(Portal, TargetComponent);
		}
	}

	void Release(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		for (int i = Grabs.Num() - 1; i >= 0; --i)
		{
			if (Grabs[i].Portal == Portal &&
				Grabs[i].TargetComponent == TargetComponent)
			{
				Grabs.RemoveAt(i);
				break;
			}
		}

		OnReleased.Broadcast(Portal, TargetComponent);

		if(Grabs.Num() == 0)
		{
			OnLastRelease.Broadcast(Portal, TargetComponent);
			//UDarkPortalEventHandler::Trigger_StopGrabbingObject(Portal, FDarkPortalGrabEventData(TargetComponent));
		}
	}

	void Push(ADarkPortalActor Portal, USceneComponent PushedComponent, const FVector& WorldLocation, const FVector& Impulse)
	{
		OnPushed.Broadcast(Portal, PushedComponent, WorldLocation, Impulse);
	}

	void Explode(ADarkPortalActor Portal, FVector Direction)
	{
		OnExploded.Broadcast(Portal, Direction);
	}

	void ApplyAttachForce(ADarkPortalActor Portal, USceneComponent AttachComponent, const FVector& Force)
	{
		for (int i = 0; i < Attaches.Num(); ++i)
		{
			if (Attaches[i].Portal == Portal &&
				Attaches[i].AttachComponent == AttachComponent)
			{
				Attaches[i].PendingForce += Force;
				break;
			}
		}
	}

	void ApplyGrabForce(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent, const FVector& Force)
	{
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].Portal == Portal &&
				Grabs[i].TargetComponent == TargetComponent)
			{
				Grabs[i].PendingForce += Force;
				break;
			}
		}
	}

	void ApplyGrabTargetLocation(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent, FVector TargetLocation, FVector TargetForwardVector)
	{
		for (int i = 0; i < Grabs.Num(); ++i)
		{
			if (Grabs[i].Portal == Portal &&
				Grabs[i].TargetComponent == TargetComponent)
			{
				Grabs[i].GrabTargetLocation = TargetLocation;
				Grabs[i].GrabTargetForward = TargetForwardVector;
				break;
			}
		}
	}

	FVector GetOriginLocationForPortal(ADarkPortalActor Portal) const
	{
		FVector PortalOrigin = Portal.OriginLocation;
		return (PortalOrigin + Portal.ActorForwardVector * PortalOriginOffset);
	}

	UFUNCTION(BlueprintPure)
	bool IsAttached() const
	{
		return (Attaches.Num() > 0);
	}

	UFUNCTION(BlueprintPure)
	bool IsGrabbed() const
	{
		return (Grabs.Num() > 0);
	}

	UFUNCTION(BlueprintPure)
	bool IsReceivingForce() const
	{
		if (IsGrabbed())
			return true;

		for (const auto& Attach : Attaches)
		{
			if (Attach.Portal != nullptr && 
				Attach.Portal.IsGrabbingAny())
				return true;
		}

		return false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugBox(Owner.ActorLocation + PortalSettleResponseBounds.Origin, PortalSettleResponseBounds.BoxExtent, Owner.ActorRotation, LineColor = FLinearColor::Yellow, Thickness = 6.0, bDrawInForeground = true);

		if(!PortalSettleResponseBounds.BoxExtent.IsZero())
			Debug::DrawDebugString(Owner.ActorLocation + PortalSettleResponseBounds.Origin, "Portal Settle Delegate Response Bounds", FLinearColor::Yellow);
	}
#endif
}