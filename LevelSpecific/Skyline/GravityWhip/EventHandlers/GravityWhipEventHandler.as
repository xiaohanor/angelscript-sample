struct FGravityWhipBeamData
{
	UPROPERTY()
	UGravityWhipTargetComponent TargetComponent;
	UPROPERTY()
	UNiagaraComponent NiagaraComponent;
	UPROPERTY()
	USplineMeshComponent MeshComponent;
	UPROPERTY()
	FVector TargetRelativeLocation;
	UPROPERTY()
	float Timestamp;

	FGravityWhipBeamData(UGravityWhipTargetComponent InTargetComponent,
		UNiagaraComponent InNiagaraComponent,
		USplineMeshComponent InMeshComponent,
		FVector InTargetRelativeLocation = FVector::ZeroVector)
	{
		TargetComponent = InTargetComponent;
		NiagaraComponent = InNiagaraComponent;
		MeshComponent = InMeshComponent;
		TargetRelativeLocation = InTargetRelativeLocation;
	}
}

class UGravityWhipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityWhipUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UGravityWhipUserComponent::Get(Owner);
	}

	// Called when the whip starts a new grab, before any individual grab has become active.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipLaunched() { }

	// Called when the whip starts retracting, after all targets have been released.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipStartRetracting() { }

	// Called when the whip has fully retracted and has become available again for a new grab.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipFinishedRetracting() { }

	// Called when the whip starts grabbing a target, before the target has received it's response event.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TargetStartGrab(FGravityWhipGrabData GrabData) { }

	// Called when the whip has grabbed a target, after the target has received it's response event.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TargetGrabbed(FGravityWhipGrabData GrabData) { }

	// Called when a target is released.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TargetReleased(FGravityWhipReleaseData ReleaseData) { }

	// Called when a grab we started turned into a hit instead, because the player released the button
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipGrabTurnedIntoHit(FGravityWhipGrabData GrabData) { }

	// Called when a hit hits the actual target
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipHitTarget(FGravityWhipGrabData GrabData) { }

	// Called when a glory kill starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipGloryKillStart() { }

	// Called when a hit lands on the target during a glory kill
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipGloryKillHit(FGravityWhipEventHandlerWhipGloryKillHitData Data) { }

	// Called when whip ability is ended, exclusive to sling mode.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TargetPreThrown(FGravityWhipReleaseData ReleaseData) { }

	// Called when a target is released, exclusive to sling mode.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TargetThrown(FGravityWhipReleaseData ReleaseData) { }

	// Called when starting an "air grab", meaning we whipped and missed, hitting nothing
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipAirGrabStart() { }
	
	// Called when the air grab is over
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipAirGrabEnd() { }

	// Called when the whip is holstered on the hip
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipHolstered() { }

	// Called when the whip is retrieved from the whip holster
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhipUnholstered() { }

	UFUNCTION(BlueprintCallable)
	void CalculateBeamCurveForGrabMode(FVector&out StartLocation,
		FVector&out StartTangent,
		FVector&out EndTangent,
		FVector&out EndLocation,
		float&out Tension,
		UGravityWhipTargetComponent TargetComponent,
		FVector RelativeLocation = FVector::ZeroVector) const
	{
		if (TargetComponent == nullptr)
			return;

		switch (UserComp.GetPrimaryGrabMode())
		{
			case EGravityWhipGrabMode::Drag:
			case EGravityWhipGrabMode::Control:
			case EGravityWhipGrabMode::ControlledDrag:
				CalculateDragBeamCurve(StartLocation, StartTangent, EndTangent, EndLocation, Tension, TargetComponent, RelativeLocation);
				break;
			case EGravityWhipGrabMode::Sling:
			case EGravityWhipGrabMode::TorHammer:
			case EGravityWhipGrabMode::GloryKill:
				CalculateSlingBeamCurve(StartLocation, StartTangent, EndTangent, EndLocation, Tension, TargetComponent, RelativeLocation);
				break;
			default:
				devError(f"Unhandled gravity whip grab mode.");
				break;
		}
	}

	void CalculateBendingTangents(
		const FVector StartLocation, 
		const FVector EndLocation, 
		FVector& StartTangent, 
		FVector& EndTangent, 
		float& Tension,
		UGravityWhipTargetComponent TargetComponent,
		FVector RelativeLocation = FVector::ZeroVector
	) const
	{
		const FVector TargetForce = TargetComponent.PrevPendingForce;
		const FVector ToTarget = (EndLocation-StartLocation);
		Tension = Math::Saturate(TargetForce.Size() / GravityWhip_VFX::MaxTensionForceSize); 

		// we want the tangent to become shorter as you get closer to the target,
		float DistToTargetScaler = ToTarget.Size() / GravityWhip_VFX::StartShrinkingTangentsDistanceThreshold;

		// we clamp it in order for our max lengths to stay true
		// and it will also give of tension in the string as you move backwards
		// because the tangents will have less bending impact on the string
		DistToTargetScaler = Math::Saturate(DistToTargetScaler);

		// resize the tangents. We use InvTension on the end because 
		// we want it to die off when the string has maximum tension to better mimic a fishing pole
		FVector BaseTangentForce = TargetForce * GravityWhip_VFX::ForceStrengthScaler * DistToTargetScaler;
		StartTangent = BaseTangentForce.GetClampedToMaxSize(GravityWhip_VFX::StartTangentMaxLength);
		EndTangent = BaseTangentForce.GetClampedToMaxSize(GravityWhip_VFX::EndTangentMaxLength);
	}

	UFUNCTION(BlueprintCallable)
	void CalculateDragBeamCurve(FVector&out StartLocation,
		FVector&out StartTangent,
		FVector&out EndTangent,
		FVector&out EndLocation,
		float&out Tension,
		UGravityWhipTargetComponent TargetComponent,
		FVector RelativeLocation = FVector::ZeroVector
		) const
	{
		FVector HandLocation = Player.Mesh.GetSocketLocation(GravityWhip::Common::AttachSocket);
		FVector TargetLocation = TargetComponent.WorldTransform.TransformPosition(RelativeLocation);

		// StartLocation = HandLocation;
		// StartTangent = StartLocation;
		// EndLocation =TargetLocation;
		// EndTangent = EndLocation;

		StartLocation = HandLocation;
		EndLocation = TargetLocation;

		CalculateBendingTangents(StartLocation, EndLocation, StartTangent, EndTangent, Tension, TargetComponent);
	}

	UFUNCTION(BlueprintCallable)
	void CalculateSlingBeamCurve(FVector&out StartLocation,
		FVector&out StartTangent,
		FVector&out EndTangent,
		FVector&out EndLocation,
		float&out Tension,
		UGravityWhipTargetComponent TargetComponent,
		FVector RelativeLocation = FVector::ZeroVector) const
	{
		FVector HandLocation = Player.Mesh.GetSocketLocation(GravityWhip::Common::AttachSocket);
		FVector TargetLocation = TargetComponent.WorldTransform.TransformPosition(RelativeLocation);

		StartLocation = HandLocation;
		EndLocation = TargetLocation;

		CalculateBendingTangents(StartLocation, EndLocation, StartTangent, EndTangent, Tension, TargetComponent);

		// StartTangent = StartLocation;
		// EndTangent = EndLocation;

		// PrintToScreenScaled("SlingMode", 0.f, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintCallable)
	void CalculateStemBeamCurve(FVector&out StartLocation,
		FVector&out StartTangent,
		FVector&out EndTangent,
		FVector&out EndLocation) const
	{
		FVector HandLocation = Player.Mesh.GetSocketLocation(GravityWhip::Common::AttachSocket);
		FVector BranchLocation = UserComp.GrabCenterLocation;

		StartLocation = HandLocation;
		EndLocation = BranchLocation;

		FVector StartToEnd = (EndLocation - StartLocation);
		float Alpha = Math::Clamp(StartToEnd.Size() / 750.0, 0.0, 1.0);

		auto AimingRay = UserComp.GetAimingRay();
		StartTangent = AimingRay.Direction * 1000.0 * Alpha;

		// @TODO: Added this to ensure it doesn't bug out. Need to find a test case for this //Sydney
		StartTangent.Normalize();

		// Debug::DrawDebugPoint(StartLocation + StartTangent, 10.0);
		// Debug::DrawDebugPoint(EndLocation + EndTangent, 10.0);

		PrintToScreenScaled("StemBeam", 0.f, FLinearColor::Yellow);
	}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "StartLocationName, StartTangentName, EndTangentName, EndLocationName"))
	void SetNiagaraBeamParameters(UNiagaraComponent NiagaraComponent,
		FVector StartLocation,
		FVector StartTangent,
		FVector EndTangent,
		FVector EndLocation,
		const FString& StartLocationName = "P0",
		const FString& StartTangentName = "P1",
		const FString& EndTangentName = "P2",
		const FString& EndLocationName = "P3",
		float Tension = 0)
	{
		if (NiagaraComponent == nullptr ||
			NiagaraComponent.IsBeingDestroyed())
			return;

		NiagaraComponent.SetNiagaraVariableVec3(StartLocationName, StartLocation);
		NiagaraComponent.SetNiagaraVariableVec3(StartTangentName, StartTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndTangentName, EndTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndLocationName, EndLocation);
		NiagaraComponent.SetNiagaraVariableFloat("Tension", Tension);
	}

	UFUNCTION(BlueprintCallable)
	void SetSplineMeshParameters(USplineMeshComponent MeshComponent,
		FVector StartLocation,
		FVector StartTangent,
		FVector EndTangent,
		FVector EndLocation)
	{
		if (MeshComponent == nullptr ||
			MeshComponent.IsBeingDestroyed())
			return;

		MeshComponent.StartPosition = StartLocation;
		MeshComponent.StartTangent = StartTangent;
		MeshComponent.EndTangent = EndTangent;
		MeshComponent.EndPosition = EndLocation;
	}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "MeshScale, MeshForwardAxis"))
	void CreateBeams(TArray<FGravityWhipBeamData>&in BeamArray,
		int MaxBeams,
		UNiagaraSystem Effect,
		UStaticMesh Mesh,
		UMaterialInterface MeshMaterial,
		FVector2D MeshScale = FVector2D::UnitVector,
		ESplineMeshAxis MeshForwardAxis = ESplineMeshAxis::X)
	{
		for (int i = BeamArray.Num(); i < MaxBeams; ++i)
		{
			if (Effect == nullptr && Mesh == nullptr)
				return;

			auto BeamData = CreateBeam(Effect, Mesh, MeshMaterial, MeshScale, MeshForwardAxis);
			if (IsBeamValid(BeamData))
				BeamArray.Add(BeamData);
		}
	}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "MeshScale, MeshForwardAxis"))
	void CreateAndAddBeam(TArray<FGravityWhipBeamData>&in BeamArray,
		UNiagaraSystem Effect,
		UStaticMesh Mesh,
		UMaterialInterface MeshMaterial,
		FVector2D MeshScale = FVector2D::UnitVector,
		ESplineMeshAxis MeshForwardAxis = ESplineMeshAxis::X)
	{
		if (Effect == nullptr && Mesh == nullptr)
			return;

		auto BeamData = CreateBeam(Effect, Mesh, MeshMaterial, MeshScale, MeshForwardAxis);
		if (IsBeamValid(BeamData))
			BeamArray.Add(BeamData);
	}

	UFUNCTION(BlueprintCallable)
	void DestroyAndRemoveBeam(TArray<FGravityWhipBeamData>&in BeamArray,
		int Index)
	{
		if (Index > 0 || Index < BeamArray.Num())
		{
			auto& Data = BeamArray[Index];
			DestroyBeam(Data);
			BeamArray.RemoveAt(Index);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DestroyAndRemoveAllBeams(TArray<FGravityWhipBeamData>&in BeamArray)
	{
		for (int i = 0; i < BeamArray.Num(); ++i)
		{
			auto& Data = BeamArray[i];
			DestroyBeam(Data);
		}

		BeamArray.Empty();
	}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "MeshScale, MeshForwardAxis"))
	FGravityWhipBeamData CreateBeam(UNiagaraSystem Effect,
		UStaticMesh Mesh,
		UMaterialInterface MeshMaterial,
		FVector2D MeshScale = FVector2D::UnitVector,
		ESplineMeshAxis MeshForwardAxis = ESplineMeshAxis::X)
	{
		FGravityWhipBeamData BeamData;
		if (Effect == nullptr && Mesh == nullptr)
			return BeamData;

		// BeamData.TargetComponent = TargetComponent;
		BeamData.Timestamp = Time::GameTimeSeconds;

		if (Mesh != nullptr)
		{
			BeamData.MeshComponent = USplineMeshComponent::Create(Owner);
			BeamData.MeshComponent.Mobility = EComponentMobility::Movable;
			BeamData.MeshComponent.CollisionEnabled = ECollisionEnabled::NoCollision;
			BeamData.MeshComponent.CastShadow = false;
			BeamData.MeshComponent.bGenerateOverlapEvents = false;
			BeamData.MeshComponent.SetStartScale(MeshScale, false);
			BeamData.MeshComponent.SetEndScale(MeshScale, false);
			BeamData.MeshComponent.SetForwardAxis(MeshForwardAxis, false);
			BeamData.MeshComponent.SetStaticMesh(Mesh);
			BeamData.MeshComponent.SetMaterial(0, MeshMaterial);
		}
				
		if (Effect != nullptr)
		{
			USceneComponent AttachComponent = Player.Mesh;
			if (BeamData.MeshComponent != nullptr)
				AttachComponent = BeamData.MeshComponent;

			// I'm being lazy here; we want it attached to the mesh because then 
			// we don't have to give mesh object to niagara, it will find it automatically.
			if(UserComp.Whip.Mesh != nullptr)
				AttachComponent = UserComp.Whip.Mesh;

			BeamData.NiagaraComponent = Niagara::SpawnLoopingNiagaraSystemAttached(Effect, AttachComponent);
		}

		return BeamData;
	}

	UFUNCTION(BlueprintCallable)
	void DestroyBeam(FGravityWhipBeamData& BeamData)
	{
		if (BeamData.NiagaraComponent != nullptr)
			BeamData.NiagaraComponent.DestroyComponent(this);

		if (BeamData.MeshComponent != nullptr)
			BeamData.MeshComponent.DestroyComponent(Owner);

		BeamData.TargetComponent = nullptr;
		BeamData.NiagaraComponent = nullptr;
		BeamData.MeshComponent = nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool IsBeamValid(const FGravityWhipBeamData& BeamData) const
	{
		return (BeamData.NiagaraComponent != nullptr || BeamData.MeshComponent != nullptr);
	}

	UFUNCTION(BlueprintCallable)
	void ReassignBeamsToTargetComponents(const TArray<UGravityWhipTargetComponent>&in TargetComponents,
		TArray<FGravityWhipBeamData>&in BeamArray)
	{
		// Don't reassign when we're no longer grabbing as the grab points
		//  will be updated for the UI, but the beams shouldn't change target
		if (!UserComp.IsGrabbingAny())
			return;

		int MaxAssignments = Math::Min(BeamArray.Num(), UserComp.GrabPoints.Num());

		for (int i = 0; i < MaxAssignments; ++i)
		{
			const auto& GrabPoint = UserComp.GrabPoints[i];

			BeamArray[i].TargetComponent = GrabPoint.TargetComponent;
			BeamArray[i].TargetRelativeLocation = GrabPoint.RelativeLocation;
		}
	}

	UFUNCTION(BlueprintPure)
	int GetMaxNumGrabs() const
	{
		return GravityWhip::Grab::MaxNumGrabs;
	}
}

namespace GravityWhip_VFX 
{
	// max lengths for the tangents. The longer they are the the bigger the bend the string will have.
	const float StartTangentMaxLength = 150;
	const float EndTangentMaxLength = 500;

	// Distance to Target at which we start shrinking the the tangents (values > 0)
	const float StartShrinkingTangentsDistanceThreshold = 1000.0;

	// Scale the incoming force to better match our Maximum lenghts
	const float ForceStrengthScaler = 0.25;

	// force size that translates to 100% tension in the string.  (values > 0)  
	// lower values might not produce maximum tension at all. 
	// High values might make it tense up immediately
	const float MaxTensionForceSize = 1000.0;
}

struct FGravityWhipEventHandlerWhipGloryKillHitData
{
	UPROPERTY(BlueprintReadOnly)
	UGravityWhipTargetComponent TargetComponent;
}