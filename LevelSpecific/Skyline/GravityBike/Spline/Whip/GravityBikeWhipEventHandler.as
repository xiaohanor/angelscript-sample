namespace GravityBikeWhip
{
	namespace VFX
	{
		const FName AttachSocket = n"RightAttach";

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
}

struct FGravityBikeWhipBeamData
{
	UPROPERTY()
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UPROPERTY()
	UNiagaraComponent NiagaraComp;

	UPROPERTY()
	USplineMeshComponent MeshComp;
	
	UPROPERTY()
	float Timestamp;

	FGravityBikeWhipBeamData(UGravityBikeWhipGrabTargetComponent InGrabTargetComp,
		UNiagaraComponent InNiagaraComp,
		USplineMeshComponent InMeshComp)
	{
		GrabTargetComp = InGrabTargetComp;
		NiagaraComp = InNiagaraComp;
		MeshComp = InMeshComp;
	}
}

struct FGravityBikeWhipGrabEventData
{
	UPROPERTY(BlueprintReadOnly)
	TArray<UGravityBikeWhipGrabTargetComponent> GrabTargets;
}

struct FGravityBikeWhipThrowEventData
{
	UPROPERTY(BlueprintReadOnly)
	TArray<FGravityBikeWhipThrowData> ThrowDatas;
}

struct FGravityBikeWhipThrowData
{
	UPROPERTY(BlueprintReadOnly)
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UPROPERTY(BlueprintReadOnly)
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;
}

struct FGravityBikeWhipDropEventData
{
	UPROPERTY(BlueprintReadOnly)
	TArray<UGravityBikeWhipGrabTargetComponent> DroppedGrabTargets;
}

UCLASS(Abstract)
class UGravityBikeWhipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable)
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY(NotEditable)
	UGravityBikeWhipComponent WhipComp = nullptr;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DefaultGrabForceFeedbackOverride = nullptr;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DefaultThrowForceFeedbackOverride = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhipComp = UGravityBikeWhipComponent::Get(Owner);
	}

	// We have started a whip, but have not started pulling the object in yet
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrab(FGravityBikeWhipGrabEventData GrabData) { }

	// After the whip is thrown, we start pulling the target in
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPull(FGravityBikeWhipGrabEventData GrabData) { }

	// If we hold the input, start lassoing the held object above the bike
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLasso(FGravityBikeWhipGrabEventData GrabData) { }

	// If we released while lassoing, we throw the held objects
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartThrow(FGravityBikeWhipThrowEventData ThrowData) { }

	// If we released while throwing/pulling, we will transition to a rebound throw instead of Lasso
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartThrowRebound(FGravityBikeWhipThrowEventData ThrowData) { }
	
	// We are completely done with this whip sequence, and will reset
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipReset() { }

	// The held object were dropped (not from player input, rather that the player died or whip became deactivated)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDropAll(FGravityBikeWhipDropEventData DropData) { }

	// Called when one or more targets were grabbed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabTargets(FGravityBikeWhipGrabEventData GrabData) { }

	// Called when one or more grabbed targets were thrown
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowTargets(FGravityBikeWhipThrowEventData ThrowData) { }

	UFUNCTION(BlueprintPure)
	TArray<UGravityBikeWhipGrabTargetComponent> GetTargetComponents()
	{
		return WhipComp.GrabbedTargets;
	}

	void CalculateBendingTangents(
		const FVector StartLocation, 
		const FVector EndLocation, 
		FVector& StartTangent, 
		FVector& EndTangent, 
		float& Tension,
		UGravityBikeWhipGrabTargetComponent GrabTargetComp
	) const
	{
		const FVector TargetForce = GravityBikeSpline::GetGravityBikeSplineTransform().TransformVectorNoScale(GrabTargetComp.GrabMoveData.GetRelativeVelocity());
		const FVector ToTarget = (EndLocation - StartLocation);
		Tension = Math::Saturate(TargetForce.Size() / GravityBikeWhip::VFX::MaxTensionForceSize); 

		// we want the tangent to become shorter as you get closer to the target,
		float DistToTargetScaler = ToTarget.Size() / GravityBikeWhip::VFX::StartShrinkingTangentsDistanceThreshold;

		// we clamp it in order for our max lengths to stay true
		// and it will also give of tension in the string as you move backwards
		// because the tangents will have less bending impact on the string
		DistToTargetScaler = Math::Saturate(DistToTargetScaler);

		// resize the tangents. We use InvTension on the end because 
		// we want it to die off when the string has maximum tension to better mimic a fishing pole
		FVector BaseTangentForce = TargetForce * GravityBikeWhip::VFX::ForceStrengthScaler * DistToTargetScaler;
		StartTangent = BaseTangentForce.GetClampedToMaxSize(GravityBikeWhip::VFX::StartTangentMaxLength);
		EndTangent = BaseTangentForce.GetClampedToMaxSize(GravityBikeWhip::VFX::EndTangentMaxLength);
	}

	UFUNCTION(BlueprintCallable)
	void CalculateSlingBeamCurve(FVector&out StartLocation,
		FVector&out StartTangent,
		FVector&out EndTangent,
		FVector&out EndLocation,
		float&out Tension,
		UGravityBikeWhipGrabTargetComponent GrabTargetComp,
		FVector RelativeLocation = FVector::ZeroVector) const
	{
		if(GrabTargetComp == nullptr)
		{
			PrintError("Trying to call CalculateSlingBeamCurve with a null GrabTargetComp!");
			return;
		}

		FVector HandLocation = Player.Mesh.GetSocketLocation(GravityBikeWhip::VFX::AttachSocket);
		FVector TargetLocation = GrabTargetComp.WorldTransform.TransformPosition(RelativeLocation);

		StartLocation = HandLocation;
		EndLocation = TargetLocation;

		CalculateBendingTangents(StartLocation, EndLocation, StartTangent, EndTangent, Tension, GrabTargetComp);
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

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "MeshScale, MeshForwardAxis"))
	void CreateAndAddBeam(TArray<FGravityBikeWhipBeamData>&in BeamArray,
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
	void DestroyAndRemoveAllBeams(TArray<FGravityBikeWhipBeamData>&in BeamArray)
	{
		for (int i = 0; i < BeamArray.Num(); ++i)
		{
			auto& Data = BeamArray[i];
			DestroyBeam(Data);
		}

		BeamArray.Empty();
	}

	FGravityBikeWhipBeamData CreateBeam(UNiagaraSystem Effect,
		UStaticMesh Mesh,
		UMaterialInterface MeshMaterial,
		FVector2D MeshScale = FVector2D(1.0, 1.0),
		ESplineMeshAxis MeshForwardAxis = ESplineMeshAxis::X)
	{
		FGravityBikeWhipBeamData BeamData;
		if (Effect == nullptr && Mesh == nullptr)
			return BeamData;

		// BeamData.TargetComponent = TargetComponent;
		BeamData.Timestamp = Time::GameTimeSeconds;

		if (Mesh != nullptr)
		{
			BeamData.MeshComp = USplineMeshComponent::Create(Owner);
			BeamData.MeshComp.Mobility = EComponentMobility::Movable;
			BeamData.MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
			BeamData.MeshComp.CastShadow = false;
			BeamData.MeshComp.bGenerateOverlapEvents = false;
			BeamData.MeshComp.SetStartScale(MeshScale, false);
			BeamData.MeshComp.SetEndScale(MeshScale, false);
			BeamData.MeshComp.SetForwardAxis(MeshForwardAxis, false);
			BeamData.MeshComp.SetStaticMesh(Mesh);
			BeamData.MeshComp.SetMaterial(0, MeshMaterial);
		}
				
		if (Effect != nullptr)
		{
			USceneComponent AttachComponent = Player.Mesh;
			if (BeamData.MeshComp != nullptr)
				AttachComponent = BeamData.MeshComp;

			// I'm being lazy here; we want it attached to the mesh because then 
			// we don't have to give mesh object to niagara, it will find it automatically.
			// if(WhipComp.Whip.Mesh != nullptr)
			// 	AttachComponent = WhipComp.Whip.Mesh;

			BeamData.NiagaraComp = Niagara::SpawnLoopingNiagaraSystemAttached(Effect, AttachComponent);
		}

		return BeamData;
	}

	UFUNCTION(BlueprintCallable)
	void DestroyBeam(FGravityBikeWhipBeamData& BeamData)
	{
		if (BeamData.NiagaraComp != nullptr)
			BeamData.NiagaraComp.DestroyComponent(this);

		if (BeamData.MeshComp != nullptr)
			BeamData.MeshComp.DestroyComponent(Owner);

		BeamData.GrabTargetComp = nullptr;
		BeamData.NiagaraComp = nullptr;
		BeamData.MeshComp = nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool IsBeamValid(const FGravityBikeWhipBeamData& BeamData) const
	{
		return (BeamData.NiagaraComp != nullptr || BeamData.MeshComp != nullptr);
	}

	UFUNCTION(BlueprintCallable)
	void ReassignBeamsToTargetComponents(const TArray<UGravityBikeWhipGrabTargetComponent>&in GrabTargetComponents,
		TArray<FGravityBikeWhipBeamData>&in BeamArray)
	{
		// Don't reassign when we're no longer grabbing as the grab points
		//  will be updated for the UI, but the beams shouldn't change target
		if (!WhipComp.HasGrabbedAnything())
			return;

		int MaxAssignments = Math::Min(BeamArray.Num(), WhipComp.GetGrabbedCount());

		for (int i = 0; i < MaxAssignments; ++i)
		{
			BeamArray[i].GrabTargetComp = WhipComp.GrabbedTargets[i];
		}
	}

	UFUNCTION(BlueprintCallable)
	UForceFeedbackEffect GetGrabForceFeedback(FGravityBikeWhipGrabEventData GrabData)
	{
		for(auto GrabTarget : GrabData.GrabTargets)
		{
			if(GrabTarget.GrabForceFeedbackOverride != nullptr)
				return GrabTarget.GrabForceFeedbackOverride;
		}

		return DefaultGrabForceFeedbackOverride;
	}

	UFUNCTION(BlueprintCallable)
	UForceFeedbackEffect GetThrowForceFeedback(FGravityBikeWhipThrowEventData ThrowData)
	{
		for(auto Throw : ThrowData.ThrowDatas)
		{
			if(Throw.GrabTargetComp.ThrowForceFeedbackOverride != nullptr)
				return Throw.GrabTargetComp.ThrowForceFeedbackOverride;
		}

		return DefaultThrowForceFeedbackOverride;
	}
}