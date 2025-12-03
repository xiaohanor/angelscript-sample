
class UCameraHideOverlappersCapability : UHazeCapability
{
	UCameraUserComponent User;
	UCameraUserComponent OtherUser;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(n"CameraHideOverlappers");

	default TickGroup = EHazeTickGroup::LastDemotable;
    default DebugCategory = CameraTags::Camera;

	TArray<AActor> HiddenActors;

	TArray<UPrimitiveComponent> HiddenComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		OtherUser = UCameraUserComponent::Get(PlayerUser.OtherPlayer);
		User.OnReset.AddUFunction(this, n"OnReset");
		User.UpdateHideOnOverlap.AddUFunction(this, n"OnForcedUpdate");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsCutsceneFullyBlendedIn())
			return false;

		if (SceneView::IsFullScreen() && (SceneView::GetFullScreenPlayer() != PlayerUser))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (IsCutsceneFullyBlendedIn())
			return true;

		if (SceneView::IsFullScreen() && (SceneView::GetFullScreenPlayer() != PlayerUser))
			return true;

		return false;
	}

	bool IsCutsceneFullyBlendedIn() const
	{
		AHazePlayerCharacter TestPlayer = PlayerUser;

		if (PlayerUser.ActiveLevelSequenceActor == nullptr)
			return false;
		UHazeCameraComponent CurCam = User.GetActiveCamera();
		if (CurCam.IsControlledByInput())
			return false;
		if (User.ActiveCameraRemainingBlendTime > 0.1)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReset()
	{
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnForcedUpdate()
	{
		Reset();
	}

	void Reset()
	{
		HiddenActors.Empty();
		HiddenComponents.Empty();
		User.ShowComponentsByInstigator(this);			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AActor> ActorsToShow = HiddenActors;
		TArray<AActor> ActorsToHide;

		TArray<UPrimitiveComponent> ComponentsToShow = HiddenComponents;
		TArray<UPrimitiveComponent> ComponentsToHide;

		FVector ViewLocation = PlayerUser.GetViewLocation();
		float OverlapRadius = 20.0 * Math::Min(1.0, PlayerUser.GetActorScale3D().Z);
		TArray<FHazeTraceSettings>  Traces;
		Traces.Add(Trace::InitChannel(ECollisionChannel::ECC_Camera, n"HideOverlapperCamera"));
		Traces.Add(Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"HideOverlapperVisibility"));
		for (FHazeTraceSettings& Trace : Traces)
		{
			Trace.UseSphereShape(OverlapRadius);
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(ViewLocation);
			for (FOverlapResult Overlap : Overlaps.OverlapResults)
			{
				// Have we found an actor to hide? (note that currently we do not hide specific components of an actor)
				if (Overlap.Component.HasTag(ComponentTags::HideOnCameraOverlap))
				{
					// Any currently hidden actors should stay hidden
					ActorsToShow.Remove(Overlap.Actor); 
					if (!HiddenActors.Contains(Overlap.Actor)) // We can't use bool return of Remove since we might find duplicates
					{
						// This actor was not previously hidden, so should be hidden now
						ActorsToHide.AddUnique(Overlap.Actor);
					}
				}
				else if (Overlap.Component.HasTag(ComponentTags::HideIndividualComponentOnCameraOverlap))
				{
					ComponentsToShow.Remove(Overlap.Component);
					if (!HiddenComponents.Contains(Overlap.Component))
						ComponentsToHide.AddUnique(Overlap.Component);
				}
			}
		}

		if (ActorsToHide.Num() > 0)
		{
			TArray<FHazeCameraHideForUserSlot>	HideSlots;
			HideSlots.Reserve(ActorsToHide.Num());
			for (AActor Actor : ActorsToHide)
			{
				// Hide characters completely, for others only hide those components 
				// with the HideOnCameraOverlap tag.
				FHazeCameraHideForUserSlot Hide;
				Hide.Actor = Actor;
				if (!Actor.IsA(AHazeCharacter))
					Hide.ComponentTag = ComponentTags::HideOnCameraOverlap;
				// Players hide attached actors as well if they're set to HideOnCameraOverlap
				if (Actor.IsA(AHazePlayerCharacter))
					Hide.AttacheesTag = ComponentTags::HideOnCameraOverlap;
				HideSlots.Add(Hide);
			}
			User.HideComponentsForUser(HideSlots, this);
			HiddenActors.Append(ActorsToHide);
		}

		if (ActorsToShow.Num() > 0)
		{
			// These are the actors which are no longer near view location
			TArray<FHazeCameraHideForUserSlot>	ShowSlots;
			ShowSlots.Reserve(ActorsToShow.Num());
			for (AActor Actor : ActorsToShow)
			{
				if (IsWithinHideThreshold(Actor, ViewLocation, OverlapRadius))
					continue; // Still too near to show.
				FHazeCameraHideForUserSlot Show;
				Show.Actor = Actor;
				if (Actor.IsA(AHazePlayerCharacter))
					Show.AttacheesTag = ComponentTags::HideOnCameraOverlap;
				ShowSlots.Add(Show);
				HiddenActors.Remove(Actor);
			}
		 	User.ShowComponentsForUser(ShowSlots, this);
		}

		// Hide individual components
		if (ComponentsToHide.Num() > 0)
		{
			User.HideComponents(ComponentsToHide, this);
			HiddenComponents.Append(ComponentsToHide);
		}

		if (ComponentsToShow.Num() > 0)
		{
			User.ShowComponents(ComponentsToShow, this);

			for (auto ShownComponent : ComponentsToShow)
				HiddenComponents.Remove(ShownComponent);
		}
	}	

	bool IsWithinHideThreshold(AActor Actor, FVector ViewLocation, float OverlapRadius)
	{
		// Actor with HideOnCameraOverlap capsule comps are only hidden 
		// when view is slightly further out from capsule 
		float HideRadius = OverlapRadius * 1.25;		
		TArray<UActorComponent> Comps;
		Actor.GetAllComponents(UCapsuleComponent, Comps);
		for (UActorComponent Comp : Comps)
		{
			UCapsuleComponent Capsule = Cast<UCapsuleComponent>(Comp);
			if (Capsule == nullptr)
				continue;
			if (!Capsule.HasTag(ComponentTags::HideOnCameraOverlap))
				continue;
			if (IsNearCapsule(ViewLocation, HideRadius, Capsule))
				return true;
		}
		// No capsule near enough, we can show actor
		return false;
	}

	bool IsNearCapsule(FVector Location, float NearRadius, UCapsuleComponent Capsule)
	{
		FVector CylinderTop = Capsule.WorldLocation + Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight;
		FVector CylinderBottom = Capsule.WorldLocation - Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight;
		FVector ClosestCapsuleCenterLoc = Math::ClosestPointOnLine(CylinderTop, CylinderBottom, Location);
		return ClosestCapsuleCenterLoc.IsWithinDist(Location, NearRadius + Capsule.GetScaledCapsuleRadius());
	}
}

